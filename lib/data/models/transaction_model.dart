import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  const TransactionModel({
    required this.id,
    required this.merchantName,
    required this.amount,
    this.potentialTaxDeduction,
    this.categoryId = 10,
    this.isBusiness,
    this.taxCategory,
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
  final String? taxCategory;
  final DateTime? transactionDate;
  final String? receiptDriveId;
  final String? receiptHash;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _asString(json['id']),
      merchantName: (json['merchantName'] as String?) ?? 'Unknown Merchant',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      potentialTaxDeduction:
          (json['potentialTaxDeduction'] as num?)?.toDouble() ??
          (json['estimatedDeduction'] as num?)?.toDouble(),
      categoryId: (json['categoryId'] as int?) ?? 10,
      isBusiness: json['isBusiness'] as bool?,
      taxCategory: _normalizeCategory(
        (json['taxCategory'] as String?) ?? (json['tax_category'] as String?),
      ),
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

  static String _asString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  static String? _normalizeCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim().toUpperCase();
  }

  TransactionModel copyWith({
    double? potentialTaxDeduction,
    int? categoryId,
    bool? isBusiness,
    String? taxCategory,
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
      taxCategory: taxCategory ?? this.taxCategory,
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
    taxCategory,
    transactionDate,
    receiptDriveId,
    receiptHash,
  ];
}
