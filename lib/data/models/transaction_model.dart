import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.merchantName,
    required this.amount,
    this.potentialTaxDeduction,
    this.categoryId = 101,
    this.isBusiness,
    this.transactionDate,
    this.receiptDriveId,
    this.receiptHash,
  });

  final String id;
  final String merchantName;
  final double amount;
  final double? potentialTaxDeduction;
  final int categoryId;
  final bool? isBusiness;
  final DateTime? transactionDate;
  final String? receiptDriveId;
  final String? receiptHash;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      merchantName: (json['merchantName'] as String?) ?? 'Unknown Merchant',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      potentialTaxDeduction:
          (json['potentialTaxDeduction'] as num?)?.toDouble() ??
          (json['estimatedDeduction'] as num?)?.toDouble(),
      categoryId: (json['categoryId'] as int?) ?? 101,
      isBusiness: json['isBusiness'] as bool?,
      transactionDate: _parseDate(json['transactionDate']),
      receiptDriveId: json['receiptDriveId'] as String?,
      receiptHash: json['receiptHash'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  TransactionModel copyWith({
    double? potentialTaxDeduction,
    int? categoryId,
    bool? isBusiness,
    DateTime? transactionDate,
    String? receiptDriveId,
    String? receiptHash,
  }) {
    return TransactionModel(
      id: id,
      merchantName: merchantName,
      amount: amount,
      potentialTaxDeduction:
          potentialTaxDeduction ?? this.potentialTaxDeduction,
      categoryId: categoryId ?? this.categoryId,
      isBusiness: isBusiness ?? this.isBusiness,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptDriveId: receiptDriveId ?? this.receiptDriveId,
      receiptHash: receiptHash ?? this.receiptHash,
    );
  }

  @override
  List<Object?> get props => [
    id,
    merchantName,
    amount,
    potentialTaxDeduction,
    categoryId,
    isBusiness,
    transactionDate,
    receiptDriveId,
    receiptHash,
  ];
}
