import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

export enum TransactionType {
  TRANSFER = 'transfer',
  REWARD = 'reward',
  PAYMENT = 'payment',
  TIP = 'tip',
}

export enum TransactionStatus {
  COMPLETED = 'completed',
  PENDING = 'pending',
  FAILED = 'failed',
}

@Entity('wallet_transactions')
export class WalletTransaction {
  @ApiProperty({ example: 'uuid-v4' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ example: 'sender-user-uuid' })
  @Index()
  @Column({ name: 'sender_id', nullable: true })
  senderId: string;

  @ApiProperty({ example: 'receiver-user-uuid' })
  @Index()
  @Column({ name: 'receiver_id' })
  receiverId: string;

  @ApiProperty({ example: '10.5000' })
  @Column({
    type: 'decimal',
    precision: 18,
    scale: 4,
  })
  amount: number;

  @ApiProperty({ enum: TransactionType, example: TransactionType.TRANSFER })
  @Column({
    type: 'enum',
    enum: TransactionType,
    default: TransactionType.TRANSFER,
  })
  type: TransactionType;

  @ApiProperty({ enum: TransactionStatus, example: TransactionStatus.COMPLETED })
  @Column({
    type: 'enum',
    enum: TransactionStatus,
    default: TransactionStatus.COMPLETED,
  })
  status: TransactionStatus;

  @ApiProperty({ example: 'Achat panier Agaseke' })
  @Column({ nullable: true })
  description: string;

  @ApiProperty({ example: 'tx_hash_sha256' })
  @Column({ name: 'tx_hash', unique: true, length: 64 })
  txHash: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}

