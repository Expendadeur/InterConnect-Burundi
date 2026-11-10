import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsUUID, IsEnum, MaxLength } from 'class-validator';
import { MessageType } from '../entities/message.entity';

export class SendMessageDto {
  @ApiProperty({ example: 'conversation-uuid' })
  @IsUUID()
  conversationId: string;

  @ApiPropertyOptional({ example: 'Bwakeye! Amakuru ki?' })
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  content?: string;

  @ApiPropertyOptional({ example: 'rn' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  originalLanguage?: string;

  @ApiPropertyOptional({ enum: MessageType, default: MessageType.TEXT })
  @IsOptional()
  @IsEnum(MessageType)
  messageType?: MessageType;

  @ApiPropertyOptional({ example: 'https://storage.interconnect.bi/audio/voice.mp3' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;
}

