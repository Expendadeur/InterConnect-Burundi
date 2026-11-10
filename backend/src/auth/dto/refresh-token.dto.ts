import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({ description: 'Valid refresh token JWT' })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
