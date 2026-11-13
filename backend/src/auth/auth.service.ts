import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  Inject,
  LoggerService,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { WINSTON_MODULE_NEST_PROVIDER } from 'nest-winston';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { User, UserStatus } from '../users/entities/user.entity';
import { JwtPayload } from './strategies/jwt.strategy';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(WINSTON_MODULE_NEST_PROVIDER)
    private readonly logger: LoggerService,
  ) {}

  async register(dto: RegisterDto): Promise<{ user: User; tokens: AuthTokens }> {
    const existingEmail = await this.usersService.findByEmail(dto.email);
    if (existingEmail) throw new ConflictException('Email already registered');

    const existingUsername = await this.usersService.findByUsername(dto.username);
    if (existingUsername) throw new ConflictException('Username already taken');

    // passwordHash will be hashed by entity BeforeInsert hook
    const user = await this.usersService.create({
      email: dto.email.toLowerCase(),
      username: dto.username,
      passwordHash: dto.password,
      firstName: dto.firstName,
      lastName: dto.lastName,
      status: UserStatus.ACTIVE,
      isOnline: true,
      lastSeenAt: new Date(),
    });

    const tokens = await this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    this.logger.log(`User registered: ${user.email}`, 'AuthService');
    return { user, tokens };
  }

  async login(dto: LoginDto): Promise<{ user: User; tokens: AuthTokens }> {
    const user = await this.usersService.findByEmail(dto.email.toLowerCase());
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const passwordValid = await user.validatePassword(dto.password);
    if (!passwordValid) throw new UnauthorizedException('Invalid credentials');

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Account is not active');
    }

    // Update online status
    await this.usersService.setOnlineStatus(user.id, true);
    user.isOnline = true;
    user.lastSeenAt = new Date();

    const tokens = await this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    this.logger.log(`User logged in: ${user.email}`, 'AuthService');
    return { user, tokens };
  }

  async logout(userId: string): Promise<void> {
    await this.usersService.updateRefreshTokenHash(userId, null);
    await this.usersService.setOnlineStatus(userId, false);
    this.logger.log(`User logged out: ${userId}`, 'AuthService');
  }

  async refreshTokens(user: User): Promise<AuthTokens> {
    const tokens = await this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);
    return tokens;
  }

  private async generateTokens(user: User): Promise<AuthTokens> {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    const accessSecret = this.configService.get<string>('jwt.accessSecret');
    const refreshSecret = this.configService.get<string>('jwt.refreshSecret');
    const accessExpiry = this.configService.get<string>('jwt.accessExpiry');
    const refreshExpiry = this.configService.get<string>('jwt.refreshExpiry');

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, { secret: accessSecret, expiresIn: accessExpiry }),
      this.jwtService.signAsync(payload, { secret: refreshSecret, expiresIn: refreshExpiry }),
    ]);

    return { accessToken, refreshToken, expiresIn: 900 };
  }

  private async storeRefreshToken(userId: string, refreshToken: string): Promise<void> {
    const hash = await bcrypt.hash(refreshToken, 10);
    await this.usersService.updateRefreshTokenHash(userId, hash);
  }
}
