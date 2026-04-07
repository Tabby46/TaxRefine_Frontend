import 'package:dio/dio.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getPendingTransactions();
  Future<List<TransactionModel>> getProcessedTransactions();
  Future<TransactionModel> swipeTransaction({
    required TransactionModel transaction,
    required bool isBusiness,
  });
  Future<void> attachReceiptMetadata({
    required String transactionId,
    required String googleDriveFileId,
    required String fileHash,
  });
}

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._apiProvider);

  final TransactionApiProvider _apiProvider;

  @override
  Future<List<TransactionModel>> getPendingTransactions() async {
    try {
      final response = await _apiProvider.fetchPendingTransactions();
      final payload = response.data;
      if (payload is List<dynamic>) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList();
      }
      return const [];
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<List<TransactionModel>> getProcessedTransactions() async {
    try {
      final response = await _apiProvider.fetchProcessedTransactions();
      final payload = response.data;
      if (payload is List<dynamic>) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList();
      }
      return const [];
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<TransactionModel> swipeTransaction({
    required TransactionModel transaction,
    required bool isBusiness,
  }) async {
    try {
      final response = await _apiProvider.swipeTransaction(
        transactionId: transaction.id,
        isBusiness: isBusiness,
        categoryId: transaction.categoryId,
      );
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return TransactionModel.fromJson(payload);
      }
      return transaction;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> attachReceiptMetadata({
    required String transactionId,
    required String googleDriveFileId,
    required String fileHash,
  }) async {
    await _apiProvider.attachReceiptMetadata(
      transactionId: transactionId,
      googleDriveFileId: googleDriveFileId,
      fileHash: fileHash,
    );
  }
}
