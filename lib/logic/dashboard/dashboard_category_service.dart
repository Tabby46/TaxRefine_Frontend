import 'package:taxrefine/core/models/category_breakdown.dart';

class DashboardCategoryService {
  /// Generates mock category breakdown data for demonstration.
  /// In a real app, this would come from the backend.
  ///
  /// This service can be enhanced later to:
  /// 1. Call a backend endpoint for category breakdown
  /// 2. Aggregate transaction data from TransactionCubit
  /// 3. Cache category data locally
  static Future<List<CategoryBreakdown>> generateCategoryBreakdown({
    required double totalDeductions,
    required int totalTransactionsCount,
    int randomSeed = 0,
  }) async {
    // Mock data - will be replaced with backend data
    if (totalDeductions == 0 || totalTransactionsCount == 0) {
      return [];
    }

    // Generate mock breakdown based on total deductions
    return [
      CategoryBreakdown(
        categoryId: 1,
        categoryName: 'Travel',
        totalAmount: totalDeductions * 0.25,
        transactionCount: (totalTransactionsCount * 0.25).toInt(),
      ),
      CategoryBreakdown(
        categoryId: 2,
        categoryName: 'Meals',
        totalAmount: totalDeductions * 0.20,
        transactionCount: (totalTransactionsCount * 0.20).toInt(),
      ),
      CategoryBreakdown(
        categoryId: 4,
        categoryName: 'Software',
        totalAmount: totalDeductions * 0.15,
        transactionCount: (totalTransactionsCount * 0.15).toInt(),
      ),
      CategoryBreakdown(
        categoryId: 3,
        categoryName: 'Office Supplies',
        totalAmount: totalDeductions * 0.12,
        transactionCount: (totalTransactionsCount * 0.12).toInt(),
      ),
      CategoryBreakdown(
        categoryId: 10,
        categoryName: 'Other Business',
        totalAmount: totalDeductions * 0.28,
        transactionCount: (totalTransactionsCount * 0.28).toInt(),
      ),
    ];
  }

  /// Sorts categories by total amount in descending order
  static List<CategoryBreakdown> sortByAmount(
    List<CategoryBreakdown> categories,
  ) {
    final sorted = [...categories];
    sorted.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return sorted;
  }

  /// Filters out categories with zero or near-zero amounts
  static List<CategoryBreakdown> filterEmpty(
    List<CategoryBreakdown> categories,
  ) {
    return categories.where((cat) => cat.totalAmount > 0.01).toList();
  }
}
