import 'package:taxrefine/data/models/transaction_model.dart';

class TransactionPageResult {
  const TransactionPageResult({required this.transactions, required this.last});

  final List<TransactionModel> transactions;
  final bool last;

  factory TransactionPageResult.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    final transactions = content is List<dynamic>
        ? content
              .whereType<Map<String, dynamic>>()
              .map(TransactionModel.fromJson)
              .toList()
        : const <TransactionModel>[];

    return TransactionPageResult(
      transactions: transactions,
      last: json['last'] == true,
    );
  }
}
