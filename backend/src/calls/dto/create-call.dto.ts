import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, IsNotEmpty } from 'class-validator';
import { CallType } from '../entities/call.entity';

export class CreateCallDto {
  @ApiProperty({ example: 'room-userA-userB' })
  @IsString()
  @IsNotEmpty()
  roomName: string;

  @ApiProperty({ enum: CallType, example: CallType.VIDEO })
  @IsEnum(CallType)
  callType: CallType;
}

