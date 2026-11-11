import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { WalletService } from './wallet.service';

@ApiTags('Wallet')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('me')
  @ApiOperation({ summary: 'Obtenir mon portefeuille de monnaie électronique ICB' })
  async getMyWallet(@Req() req: any) {
    return this.walletService.getOrCreateWallet(req.user.id);
  }

  @Post('transfer')
  @ApiOperation({ summary: 'Transférer des jetons ICB à un autre utilisateur' })
  async transfer(
    @Req() req: any,
    @Body('receiverAddress') receiverAddress: string,
    @Body('amount') amount: number,
    @Body('description') description?: string,
  ) {
    return this.walletService.transfer(req.user.id, receiverAddress, Number(amount), description);
  }

  @Get('transactions')
  @ApiOperation({ summary: 'Consulter l’historique des transactions sur le registre' })
  async getTransactions(@Req() req: any) {
    return this.walletService.getHistory(req.user.id);
  }
}

