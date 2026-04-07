import 'package:equatable/equatable.dart';
import 'package:taxrefine/data/models/transaction_model.dart';

enum TransactionFeedbackType { info, success, warning }

sealed class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => const [];
}

final class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

final class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  const TransactionLoaded({
    required this.transactions,
    this.feedbackMessage,
    this.feedbackToken = 0,
    this.feedbackType = TransactionFeedbackType.info,
  });

  final List<TransactionModel> transactions;
  final String? feedbackMessage;
  final int feedbackToken;
  final TransactionFeedbackType feedbackType;

  TransactionLoaded copyWith({
    List<TransactionModel>? transactions,
    String? feedbackMessage,
    int? feedbackToken,
    TransactionFeedbackType? feedbackType,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      feedbackMessage: feedbackMessage,
      feedbackToken: feedbackToken ?? this.feedbackToken,
      feedbackType: feedbackType ?? this.feedbackType,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    feedbackMessage,
    feedbackToken,
    feedbackType,
  ];
}

final class TransactionUploadingReceipt extends TransactionLoaded {
  const TransactionUploadingReceipt({
    required super.transactions,
    required this.uploadingTransactionId,
    super.feedbackMessage,
    super.feedbackToken,
    super.feedbackType,
  });

  final String uploadingTransactionId;

  @override
  List<Object?> get props => [...super.props, uploadingTransactionId];
}

final class TransactionError extends TransactionState {
  const TransactionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
