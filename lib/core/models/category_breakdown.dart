import 'package:equatable/equatable.dart';

class CategoryBreakdown extends Equatable {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
  });

  final int categoryId;
  final String categoryName;
  final double totalAmount;
  final int transactionCount;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: (json['categoryId'] as int?) ?? 0,
      categoryName: (json['categoryName'] as String?) ?? 'Other',
      totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
      transactionCount: (json['transactionCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
    };
  }

  @override
  List<Object> get props => [
    categoryId,
    categoryName,
    totalAmount,
    transactionCount,
  ];
}

class CategoryBreakdownMapping {
  static const Map<int, String> categoryIdToName = {
    1: 'Travel',
    2: 'Meals',
    3: 'Office Supplies',
    4: 'Software',
    5: 'Phone',
    6: 'Internet',
    7: 'Office Rent',
    8: 'Utilities',
    9: 'Equipment',
    10: 'Other Business',
  };

  static String getCategoryName(int categoryId) {
    return categoryIdToName[categoryId] ?? 'Other';
  }

  static IconCategory getIconCategory(int categoryId) {
    switch (categoryId) {
      case 1:
        return IconCategory.travel;
      case 2:
        return IconCategory.meals;
      case 3:
        return IconCategory.supplies;
      case 4:
        return IconCategory.software;
      case 5:
        return IconCategory.phone;
      case 6:
        return IconCategory.internet;
      case 7:
        return IconCategory.building;
      case 8:
        return IconCategory.utilities;
      case 9:
        return IconCategory.equipment;
      default:
        return IconCategory.other;
    }
  }
}

enum IconCategory {
  travel,
  meals,
  supplies,
  software,
  phone,
  internet,
  building,
  utilities,
  equipment,
  other,
}

extension IconCategoryExt on IconCategory {
  String get icon {
    switch (this) {
      case IconCategory.travel:
        return '✈️';
      case IconCategory.meals:
        return '🍽️';
      case IconCategory.supplies:
        return '📎';
      case IconCategory.software:
        return '💻';
      case IconCategory.phone:
        return '📱';
      case IconCategory.internet:
        return '📡';
      case IconCategory.building:
        return '🏢';
      case IconCategory.utilities:
        return '⚡';
      case IconCategory.equipment:
        return '🔧';
      case IconCategory.other:
        return '📦';
    }
  }
}
