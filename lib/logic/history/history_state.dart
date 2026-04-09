import 'package:equatable/equatable.dart';
import 'package:taxrefine/data/models/transaction_model.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => const [];
}

final class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

final class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

final class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.transactions);

  final List<TransactionModel> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class HistoryUploadingReceipt extends HistoryLoaded {
  const HistoryUploadingReceipt(
    super.transactions, {
    required this.uploadingTransactionId,
  });

  final String uploadingTransactionId;

  @override
  List<Object?> get props => [...super.props, uploadingTransactionId];
}

final class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
