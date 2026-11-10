import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AccessToken } from 'livekit-server-sdk';
import { Call, CallType, CallStatus } from './entities/call.entity';
import { CreateCallDto } from './dto/create-call.dto';

@Injectable()
export class CallsService {
  private readonly logger = new Logger(CallsService.name);

  constructor(
    @InjectRepository(Call)
    private readonly callRepo: Repository<Call>,
    private readonly configService: ConfigService,
  ) {}

  async createCall(callerId: string, dto: CreateCallDto): Promise<Call> {
    const call = this.callRepo.create({
      callerId,
      roomName: dto.roomName,
      callType: dto.callType,
      status: CallStatus.RINGING,
    });
    return this.callRepo.save(call);
  }

  async generateToken(roomName: string, participantIdentity: string, participantName?: string): Promise<string> {
    const apiKey = this.configService.get<string>('livekit.apiKey');
    const apiSecret = this.configService.get<string>('livekit.apiSecret');

    if (!apiKey || !apiSecret) {
      this.logger.warn('LiveKit credentials non configurées dans .env');
      return 'mock-token-for-dev';
    }

    const at = new AccessToken(apiKey, apiSecret, {
      identity: participantIdentity,
      name: participantName || participantIdentity,
    });

    at.addGrant({
      room: roomName,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
    });

    return at.toJwt();
  }

  async endCall(roomName: string): Promise<void> {
    await this.callRepo.update(
      { roomName },
      { status: CallStatus.ENDED, endedAt: new Date() },
    );
  }
}

