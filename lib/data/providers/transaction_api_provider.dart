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

  Future<Response<dynamic>> fetchUserTransactionsPage({
    required String userId,
    String? taxCategory,
    required int page,
    required int size,
  }) {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'transactionDate,desc',
    };

    if (taxCategory != null && taxCategory.isNotEmpty) {
      query['tax_category'] = taxCategory;
    }

    return _dioClient.dio.get(
      '/transactions/user/$userId',
      queryParameters: query,
    );
  }

  Future<Response<dynamic>> swipeTransaction({
    required String transactionId,
    required bool isBusiness,
    required int categoryId,
    String? receiptContent,
    String? receiptFileName,
    String? receiptMimeType,
  }) {
    final data = <String, dynamic>{
      'isBusiness': isBusiness,
      'categoryId': categoryId,
    };

    if (receiptContent != null && receiptContent.isNotEmpty) {
      data['receiptContent'] = receiptContent;
      data['receiptFileName'] = receiptFileName;
      data['receiptMimeType'] = receiptMimeType;
    } else if (isBusiness) {
      // Explicitly mark this as a business swipe without an attached receipt.
      data['receiptContent'] = null;
      data['receiptFileName'] = null;
      data['receiptMimeType'] = null;
    }

    return _dioClient.dio.post(
      '/transactions/$transactionId/swipe',
      data: data,
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

  Future<Response<dynamic>> attachReceiptContent({
    required String transactionId,
    required String receiptContent,
    required String receiptFileName,
    required String receiptMimeType,
  }) {
    return _dioClient.dio.patch(
      '/transactions/$transactionId/receipt',
      data: {
        'receiptContent': receiptContent,
        'receiptFileName': receiptFileName,
        'receiptMimeType': receiptMimeType,
      },
    );
  }

  Future<Response<dynamic>> updateTransactionTaxCategory({
    required String transactionId,
    required String taxCategory,
  }) {
    return _dioClient.dio.patch(
      '/transactions/$transactionId',
      data: {'taxCategory': taxCategory},
    );
  }

  Future<Response<dynamic>> fetchDeductionSummary({required String userId}) {
    return _dioClient.dio.get(
      '/transactions/summary',
      queryParameters: {'userId': userId},
    );
  }

  Future<Response<dynamic>> fetchReviewStatus({required String userId}) {
    return _dioClient.dio.get(
      '/transactions/review-status',
      queryParameters: {'userId': userId},
    );
  }

  Future<Response<dynamic>> fetchCategoryBreakdown({required String userId}) {
    return _dioClient.dio.get(
      '/transactions/category-breakdown',
      queryParameters: {'userId': userId},
    );
  }
}
