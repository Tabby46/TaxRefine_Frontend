import 'package:dio/dio.dart';
import 'package:taxrefine/core/network/dio_client.dart';

class TransactionApiProvider {
  TransactionApiProvider(this._dioClient);

  final DioClient _dioClient;

  Future<Response<dynamic>> fetchPendingTransactions() {
    return _dioClient.dio.get('/transactions');
  }

  Future<Response<dynamic>> fetchProcessedTransactions() {
    return _dioClient.dio.get(
      '/transactions',
      queryParameters: {'status': 'PROCESSED'},
    );
  }

  Future<Response<dynamic>> swipeTransaction({
    required String transactionId,
    required bool isBusiness,
    required int categoryId,
  }) {
    return _dioClient.dio.post(
      '/transactions/$transactionId/swipe',
      data: {'isBusiness': isBusiness, 'categoryId': categoryId},
    );
  }

  Future<Response<dynamic>> attachReceiptMetadata({
    required String transactionId,
    required String googleDriveFileId,
    required String fileHash,
  }) {
    return _dioClient.dio.patch(
      '/transactions/$transactionId/receipt',
      data: {'googleDriveFileId': googleDriveFileId, 'fileHash': fileHash},
    );
  }
}
