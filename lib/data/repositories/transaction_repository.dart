import 'package:dio/dio.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getPendingTransactions();
  Future<List<TransactionModel>> getProcessedTransactions();
  Future<TransactionModel> swipeTransaction({
    required TransactionModel transaction,
    required bool isBusiness,
    String? receiptContent,
    String? receiptFileName,
    String? receiptMimeType,
  });
  Future<void> attachReceiptMetadata({
    required String transactionId,
    required String googleDriveFileId,
    required String fileHash,
  });
  Future<TransactionModel?> attachReceiptContent({
    required String transactionId,
    required String receiptContent,
    required String receiptFileName,
    required String receiptMimeType,
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
      
      // Debug logging for empty responses
      print('[TransactionRepository] GET /transactions returned: ${payload.runtimeType}, length: ${payload is List ? payload.length : "N/A"}');
      if (payload is List && payload.isEmpty) {
        print('[TransactionRepository] WARNING: Received empty transaction list from backend');
      }
      
      if (payload is List<dynamic>) {
        return payload
            .whereType<Map<String, dynamic>>()
            .map(TransactionModel.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      print('[TransactionRepository] API Error: ${e.response?.statusCode} ${e.message}');
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
    String? receiptContent,
    String? receiptFileName,
    String? receiptMimeType,
  }) async {
    try {
      final response = await _apiProvider.swipeTransaction(
        transactionId: transaction.id,
        isBusiness: isBusiness,
        categoryId: transaction.categoryId,
        receiptContent: receiptContent,
        receiptFileName: receiptFileName,
        receiptMimeType: receiptMimeType,
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

  @override
  Future<TransactionModel?> attachReceiptContent({
    required String transactionId,
    required String receiptContent,
    required String receiptFileName,
    required String receiptMimeType,
  }) async {
    try {
      final response = await _apiProvider.attachReceiptContent(
        transactionId: transactionId,
        receiptContent: receiptContent,
        receiptFileName: receiptFileName,
        receiptMimeType: receiptMimeType,
      );

      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        return TransactionModel.fromJson(payload);
      }
      return null;
    } on DioException {
      rethrow;
    }
  }
}
