import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/data/providers/google_drive_provider.dart';
import 'package:taxrefine/data/repositories/transaction_repository.dart';
import 'package:taxrefine/logic/transactions/transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  TransactionCubit(this._repository, this._googleDriveProvider)
    : super(const TransactionInitial());

  final TransactionRepository _repository;
  final GoogleDriveProvider _googleDriveProvider;
  int _feedbackToken = 0;

  Future<void> loadPendingTransactions() async {
    emit(const TransactionLoading());
    try {
      final items = await _repository.getPendingTransactions();
      // Fixed: Show all transactions that need review, regardless of isBusiness status
      final pending = items.where((item) => 
        item.taxCategory == null || 
        item.taxCategory == 'NEEDS_REVIEW'
      ).toList();
      emit(TransactionLoaded(transactions: pending));
    } catch (_) {
      emit(const TransactionError(AppStrings.loadingTransactionsFailed));
    }
  }

  Future<bool> swipe({
    required bool isBusiness,
    required int swipedIndex,
    int? categoryId,
    File? receiptFile,
  }) async {
    final current = state;
    if (current is! TransactionLoaded || current.transactions.isEmpty) {
      return false;
    }

    if (swipedIndex < 0 || swipedIndex >= current.transactions.length) {
      return false;
    }

    final transaction = current.transactions[swipedIndex];
    final transactionsSnapshot = List<TransactionModel>.from(
      current.transactions,
    );

    if (isBusiness) {
      emit(
        TransactionUploadingReceipt(
          transactions: transactionsSnapshot,
          uploadingTransactionId: transaction.id,
        ),
      );
    }

    try {
      final updated = await _repository.swipeTransaction(
        transaction: transaction,
        isBusiness: isBusiness,
        categoryId: categoryId,
      );

      final remaining = List<TransactionModel>.from(current.transactions)
        ..removeAt(swipedIndex);

      String feedback = AppStrings.personalSwipeSaved;
      var feedbackType = TransactionFeedbackType.info;
      if (isBusiness) {
        final deduction = updated.potentialTaxDeduction ?? 0;
        feedback = AppStrings.businessSwipeSaved(deduction);

        if (receiptFile != null) {
          try {
            final uploadResult = await _googleDriveProvider.uploadReceipt(
              receiptFile,
            );
            await _repository.attachReceiptMetadata(
              transactionId: updated.id,
              googleDriveFileId: uploadResult.googleDriveFileId,
              fileHash: uploadResult.fileHash,
            );
          } on GoogleSignInException catch (ex) {
            if (ex.code != GoogleSignInExceptionCode.canceled) {
              feedbackType = TransactionFeedbackType.warning;
              if (ex.code ==
                  GoogleSignInExceptionCode.clientConfigurationError) {
                feedback =
                    '${AppStrings.businessSwipeSaved(deduction)} ${AppStrings.googleSignInConfigurationError}';
              } else {
                feedback =
                    '${AppStrings.businessSwipeSaved(deduction)} Google sign-in for Drive failed (${ex.code.name}).';
              }
            }
          } on GoogleDriveUploadException catch (ex) {
            feedbackType = TransactionFeedbackType.warning;
            feedback =
                '${AppStrings.businessSwipeSaved(deduction)} ${ex.message}';
          } on DioException {
            feedbackType = TransactionFeedbackType.warning;
            feedback =
                '${AppStrings.businessSwipeSaved(deduction)} ${AppStrings.receiptBackendSyncFailed}';
          }
        }
      }

      _feedbackToken++;
      emit(
        current.copyWith(
          transactions: remaining,
          feedbackMessage: feedback,
          feedbackToken: _feedbackToken,
          feedbackType: feedbackType,
        ),
      );
      return true;
    } on DioException {
      _feedbackToken++;
      emit(
        current.copyWith(
          transactions: transactionsSnapshot,
          feedbackMessage: AppStrings.swipeSaveFailed,
          feedbackToken: _feedbackToken,
          feedbackType: TransactionFeedbackType.warning,
        ),
      );
      return false;
    } catch (_) {
      _feedbackToken++;
      emit(
        current.copyWith(
          transactions: transactionsSnapshot,
          feedbackMessage: AppStrings.swipeSaveFailed,
          feedbackToken: _feedbackToken,
          feedbackType: TransactionFeedbackType.warning,
        ),
      );
      return false;
    }
  }

  Future<void> uploadReceiptAndSync({
    required TransactionModel transaction,
    required File file,
  }) async {
    final current = state;
    if (current is! TransactionLoaded) {
      return;
    }

    final transactionsSnapshot = List<TransactionModel>.from(
      current.transactions,
    );

    emit(
      TransactionUploadingReceipt(
        transactions: transactionsSnapshot,
        uploadingTransactionId: transaction.id,
      ),
    );

    try {
      final result = await _googleDriveProvider.uploadReceipt(file);
      await _repository.attachReceiptMetadata(
        transactionId: transaction.id,
        googleDriveFileId: result.googleDriveFileId,
        fileHash: result.fileHash,
      );

      final updatedTransactions = current.transactions.map((item) {
        if (item.id != transaction.id) {
          return item;
        }
        return item.copyWith(
          receiptDriveId: result.googleDriveFileId,
          receiptHash: result.fileHash,
        );
      }).toList();

      _feedbackToken++;
      emit(
        TransactionLoaded(
          transactions: updatedTransactions,
          feedbackMessage: AppStrings.receiptSecuredInDrive,
          feedbackToken: _feedbackToken,
          feedbackType: TransactionFeedbackType.success,
        ),
      );
    } on GoogleSignInException catch (ex) {
      if (ex.code == GoogleSignInExceptionCode.canceled) {
        _emitUploadWarning(
          transactionsSnapshot,
          AppStrings.googleSignInCancelled,
        );
        return;
      }
      if (ex.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _emitUploadWarning(
          transactionsSnapshot,
          AppStrings.googleSignInConfigurationError,
        );
        return;
      }
      _emitUploadWarning(
        transactionsSnapshot,
        'Google sign-in for Drive failed (${ex.code.name}).',
      );
    } on GoogleDriveUploadException catch (ex) {
      _emitUploadWarning(transactionsSnapshot, ex.message);
    } on DioException {
      _emitUploadWarning(
        transactionsSnapshot,
        AppStrings.receiptBackendSyncFailed,
      );
    } catch (_) {
      _emitUploadWarning(transactionsSnapshot, AppStrings.receiptUploadFailed);
    }
  }

  void _emitUploadWarning(List<TransactionModel> transactions, String message) {
    _feedbackToken++;
    emit(
      TransactionLoaded(
        transactions: transactions,
        feedbackMessage: message,
        feedbackToken: _feedbackToken,
        feedbackType: TransactionFeedbackType.warning,
      ),
    );
  }
}
