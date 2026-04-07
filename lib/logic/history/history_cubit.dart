import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/repositories/transaction_repository.dart';
import 'package:taxrefine/logic/history/history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryInitial());

  final TransactionRepository _repository;

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
}
