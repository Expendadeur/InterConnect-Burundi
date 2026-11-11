import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WalletTransactionModel {
  final String id;
  final String? senderId;
  final String receiverId;
  final double amount;
  final String type;
  final String status;
  final String? description;
  final String txHash;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    this.senderId,
    required this.receiverId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.txHash,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] ?? '',
      senderId: json['senderId'],
      receiverId: json['receiverId'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? 'transfer',
      status: json['status'] ?? 'completed',
      description: json['description'],
      txHash: json['txHash'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletState {
  final double tokenBalance;
  final String walletAddress;
  final List<WalletTransactionModel> transactions;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.tokenBalance = 0.0,
    this.walletAddress = '',
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiClient _apiClient;

  WalletNotifier(this._apiClient) : super(const WalletState()) {
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    state = WalletState(
      tokenBalance: state.tokenBalance,
      walletAddress: state.walletAddress,
      transactions: state.transactions,
      isLoading: true,
    );

    try {
      final resWallet = await _apiClient.dio.get('/wallet/me');
      final balance = double.tryParse(resWallet.data['tokenBalance']?.toString() ?? '0') ?? 0.0;
      final address = resWallet.data['walletAddress']?.toString() ?? '';

      final resTx = await _apiClient.dio.get('/wallet/transactions');
      List<dynamic> raw = [];
      if (resTx.data is List) {
        raw = resTx.data;
      }

      final txList = raw.map((j) => WalletTransactionModel.fromJson(j)).toList();

      state = WalletState(
        tokenBalance: balance,
        walletAddress: address,
        transactions: txList,
        isLoading: false,
      );
    } catch (e) {
      state = WalletState(
        tokenBalance: state.tokenBalance,
        walletAddress: state.walletAddress,
        transactions: state.transactions,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> transferTokens({
    required String receiverAddress,
    required double amount,
    String? description,
  }) async {
    try {
      await _apiClient.dio.post('/wallet/transfer', data: {
        'receiverAddress': receiverAddress,
        'amount': amount,
        'description': description,
      });
      await fetchWallet();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final client = ref.watch(apiClientProvider);
  return WalletNotifier(client);
});

