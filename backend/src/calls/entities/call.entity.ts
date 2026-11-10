import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum CallType {
  AUDIO = 'audio',
  VIDEO = 'video',
  GROUP = 'group',
}

export enum CallStatus {
  RINGING = 'ringing',
  ACTIVE = 'active',
  ENDED = 'ended',
  MISSED = 'missed',
}

@Entity('calls')
export class Call {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'room_name', unique: true })
  roomName: string;

  @Column({ name: 'caller_id' })
  callerId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'caller_id' })
  caller: User;

  @Column({ name: 'call_type', length: 20 })
  callType: CallType;

  @Column({ length: 20, default: CallStatus.RINGING })
  status: CallStatus;

  @Column({ name: 'started_at', nullable: true, type: 'timestamptz' })
  startedAt: Date;

  @Column({ name: 'ended_at', nullable: true, type: 'timestamptz' })
  endedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

