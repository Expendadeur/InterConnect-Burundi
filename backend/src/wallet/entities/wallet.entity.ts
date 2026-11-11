import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('wallets')
export class Wallet {
  @ApiProperty({ example: 'uuid-v4' })
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ApiProperty({ example: 'user-uuid' })
  @Index({ unique: true })
  @Column({ name: 'user_id' })
  userId: string;

  @ApiProperty({ example: '0.00', description: 'Solde en monnaie électronique native ICB' })
  @Column({
    name: 'token_balance',
    type: 'decimal',
    precision: 18,
    scale: 4,
    default: 0.0,
  })
  tokenBalance: number;

  @ApiProperty({ example: 'ICB-WALLET-9A8B7C' })
  @Index({ unique: true })
  @Column({ name: 'wallet_address', length: 64 })
  walletAddress: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}

