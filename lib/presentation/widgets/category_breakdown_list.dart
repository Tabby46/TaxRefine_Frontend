import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/models/category_breakdown.dart';

class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  final List<CategoryBreakdown> categories;
  final Function(CategoryBreakdown)? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryBreakdownRow(
              category: category,
              index: index,
              onTap: () => onCategoryTap?.call(category),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No category breakdown available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.category,
    required this.index,
    required this.onTap,
  });

  final CategoryBreakdown category;
  final int index;
  final VoidCallback onTap;

  static const List<Color> chartColors = [
    Color(0xFF0B6E4F), // Primary teal
    Color(0xFF15A08C), // Light teal
    Color(0xFF2FB598), // Medium teal
    Color(0xFF48C9B0), // Lighter teal
    Color(0xFF64D9C4), // Pale teal
    Color(0xFF1B5E7F), // Deep blue
    Color(0xFF2A7FA3), // Medium blue
    Color(0xFF3BA0C8), // Light blue
    Color(0xFF4CB8D9), // Sky blue
    Color(0xFF6DD4E8), // Very light blue
  ];

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final color = chartColors[index % chartColors.length];
    final iconCategory = CategoryBreakdownMapping.getIconCategory(
      category.categoryId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                iconCategory.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            category.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '${category.transactionCount} transaction${category.transactionCount != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(category.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Est.',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
