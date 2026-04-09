import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/providers/google_drive_provider.dart';
import 'package:taxrefine/data/repositories/transaction_repository.dart';
import 'package:taxrefine/logic/history/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository, this._googleDriveProvider)
    : super(const HistoryInitial());

  final TransactionRepository _repository;
  final GoogleDriveProvider _googleDriveProvider;

  Future<void> loadHistory() async {
    emit(const HistoryLoading());
    try {
      final transactions = await _repository.getProcessedTransactions();
      final processed = transactions
          .where((transaction) => transaction.isBusiness != null)
          .toList();
      emit(HistoryLoaded(processed));
    } catch (_) {
      emit(const HistoryError(AppStrings.loadingTransactionsFailed));
    }
  }

  Future<void> attachReceiptLater({
    required String transactionId,
    required File file,
  }) async {
    final current = state;
    if (current is! HistoryLoaded) {
      return;
    }

    final snapshot = List.of(current.transactions);
    emit(
      HistoryUploadingReceipt(snapshot, uploadingTransactionId: transactionId),
    );

    try {
      final result = await _googleDriveProvider.uploadReceipt(file);
      await _repository.attachReceiptMetadata(
        transactionId: transactionId,
        googleDriveFileId: result.googleDriveFileId,
        fileHash: result.fileHash,
      );

      final updated = snapshot.map((item) {
        if (item.id != transactionId) {
          return item;
        }
        return item.copyWith(
          receiptDriveId: result.googleDriveFileId,
          receiptHash: result.fileHash,
        );
      }).toList();

      emit(HistoryLoaded(updated));
    } on GoogleSignInException catch (ex) {
      if (ex.code == GoogleSignInExceptionCode.canceled) {
        emit(HistoryLoaded(snapshot));
        return;
      }
      if (ex.code == GoogleSignInExceptionCode.clientConfigurationError) {
        emit(const HistoryError(AppStrings.googleSignInConfigurationError));
        return;
      }
      emit(HistoryError('Google sign-in for Drive failed (${ex.code.name}).'));
    } on GoogleDriveUploadException catch (ex) {
      emit(HistoryError(ex.message));
    } on DioException {
      emit(const HistoryError(AppStrings.receiptBackendSyncFailed));
    } catch (ex) {
      emit(HistoryError('Unexpected receipt upload error: $ex'));
    }
  }
}
