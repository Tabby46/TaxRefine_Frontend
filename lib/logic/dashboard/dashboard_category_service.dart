import 'package:dio/dio.dart';
import 'package:taxrefine/core/models/category_breakdown.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';

class DashboardCategoryService {
  /// Generates category breakdown data from the backend API.
  ///
  /// Fetches aggregated transaction data grouped by category ID,
  /// including total amounts and transaction counts per category.
  ///
  /// Falls back to empty list if API call fails or returns no data.
  static Future<List<CategoryBreakdown>> generateCategoryBreakdown({
    required double totalDeductions,
    required int totalTransactionsCount,
    required String userId,
    required TransactionApiProvider apiProvider,
    int randomSeed = 0,
  }) async {
    // Return empty if totals are zero (no transactions)
    if (totalDeductions == 0 || totalTransactionsCount == 0) {
      return [];
    }

    try {
      final response = await apiProvider.fetchCategoryBreakdown(userId: userId);

      final payload = response.data;
      if (payload is! List) {
        throw const FormatException('Invalid category breakdown response');
      }

      // Convert backend response to CategoryBreakdown objects
      return (payload).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid category item');
        }
        return CategoryBreakdown.fromJson(item);
      }).toList();
    } on DioException {
      // API call failed - return empty list
      return [];
    } catch (_) {
      // Parsing or other error - return empty list
      return [];
    }
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
