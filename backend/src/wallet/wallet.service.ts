import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as crypto from 'crypto';
import { Wallet } from './entities/wallet.entity';
import {
  WalletTransaction,
  TransactionType,
  TransactionStatus,
} from './entities/wallet-transaction.entity';

@Injectable()
export class WalletService {
  constructor(
    @InjectRepository(Wallet)
    private readonly walletRepository: Repository<Wallet>,
    @InjectRepository(WalletTransaction)
    private readonly txRepository: Repository<WalletTransaction>,
    private readonly dataSource: DataSource,
  ) {}

  /**
   * Récupère ou génère automatiquement le portefeuille d'un utilisateur
   */
  async getOrCreateWallet(userId: string): Promise<Wallet> {
    let wallet = await this.walletRepository.findOne({ where: { userId } });
    if (!wallet) {
      const address = 'ICB-' + crypto.randomBytes(6).toString('hex').toUpperCase();
      wallet = this.walletRepository.create({
        userId,
        tokenBalance: 0.0,
        walletAddress: address,
      });
      wallet = await this.walletRepository.save(wallet);
    }
    return wallet;
  }

  /**
   * Transfère des tokens ICB entre deux membres
   */
  async transfer(senderId: string, receiverWalletAddress: string, amount: number, description?: string): Promise<WalletTransaction> {
    if (amount <= 0) {
      throw new BadRequestException('Le montant doit être supérieur à 0');
    }

    return this.dataSource.transaction(async (manager) => {
      const senderWallet = await manager.findOne(Wallet, { where: { userId: senderId } });
      if (!senderWallet || Number(senderWallet.tokenBalance) < amount) {
        throw new BadRequestException('Solde ICB insuffisant');
      }

      const receiverWallet = await manager.findOne(Wallet, { where: { walletAddress: receiverWalletAddress } });
      if (!receiverWallet) {
        throw new NotFoundException('Adresse de portefeuille destinataire introuvable');
      }

      if (senderWallet.userId === receiverWallet.userId) {
        throw new BadRequestException('Impossible d’effectuer un transfert vers votre propre compte');
      }

      // Débit expéditeur
      senderWallet.tokenBalance = Number(senderWallet.tokenBalance) - amount;
      await manager.save(senderWallet);

      // Crédit destinataire
      receiverWallet.tokenBalance = Number(receiverWallet.tokenBalance) + amount;
      await manager.save(receiverWallet);

      // Hash cryptographique de la transaction
      const rawData = `${senderId}-${receiverWallet.userId}-${amount}-${Date.now()}`;
      const txHash = crypto.createHash('sha256').update(rawData).digest('hex');

      const tx = manager.create(WalletTransaction, {
        senderId,
        receiverId: receiverWallet.userId,
        amount,
        type: TransactionType.TRANSFER,
        status: TransactionStatus.COMPLETED,
        description: description || 'Transfert de jetons ICB',
        txHash,
      });

      return manager.save(tx);
    });
  }

  /**
   * Historique des transactions
   */
  async getHistory(userId: string): Promise<WalletTransaction[]> {
    return this.txRepository.find({
      where: [
        { senderId: userId },
        { receiverId: userId },
      ],
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }
}

