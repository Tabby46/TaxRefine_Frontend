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

  // Use new business category colors

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.forCategoryId(category.categoryId);
    final iconCategory = CategoryBreakdownMapping.getIconCategory(
      category.categoryId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10, width: 1),
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
              color: Colors.white12,
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '${category.transactionCount} transaction${category.transactionCount != 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Est.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
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
