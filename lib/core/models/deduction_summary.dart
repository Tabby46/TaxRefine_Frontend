import 'package:equatable/equatable.dart';

class DeductionSummary extends Equatable {
  const DeductionSummary({
    required this.totalDeductions,
    required this.totalTransactionsCount,
    required this.reviewedTransactionsCount,
  });

  final double totalDeductions;
  final int totalTransactionsCount;
  final int reviewedTransactionsCount;

  /// Calculates estimated tax savings as 30% of total deductions.
  double get estimatedSavings => totalDeductions * 0.30;

  /// Calculates the review progress percentage (0.0 to 1.0).
  double get reviewProgress {
    if (totalTransactionsCount == 0) {
      return 0.0;
    }
    return reviewedTransactionsCount / totalTransactionsCount;
  }

  /// Calculates the review progress as a percentage (0 to 100).
  int get reviewProgressPercentage => (reviewProgress * 100).toInt();

  factory DeductionSummary.fromJson(Map<String, dynamic> json) {
    return DeductionSummary(
      totalDeductions: ((json['totalDeductions'] as num?) ?? 0).toDouble(),
      totalTransactionsCount: (json['totalTransactionsCount'] as int?) ?? 0,
      reviewedTransactionsCount:
          (json['reviewedTransactionsCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeductions': totalDeductions,
      'totalTransactionsCount': totalTransactionsCount,
      'reviewedTransactionsCount': reviewedTransactionsCount,
    };
  }

  DeductionSummary copyWith({
    double? totalDeductions,
    int? totalTransactionsCount,
    int? reviewedTransactionsCount,
  }) {
    return DeductionSummary(
      totalDeductions: totalDeductions ?? this.totalDeductions,
      totalTransactionsCount:
          totalTransactionsCount ?? this.totalTransactionsCount,
      reviewedTransactionsCount:
          reviewedTransactionsCount ?? this.reviewedTransactionsCount,
    );
  }

  @override
  List<Object> get props => [
    totalDeductions,
    totalTransactionsCount,
    reviewedTransactionsCount,
  ];
}
