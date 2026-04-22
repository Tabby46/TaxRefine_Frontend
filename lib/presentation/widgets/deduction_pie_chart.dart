import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:taxrefine/core/models/category_breakdown.dart';

class DeductionPieChart extends StatelessWidget {
  const DeductionPieChart({
    super.key,
    required this.categories,
    this.totalAmount = 0,
    this.onTap,
  });

  final List<CategoryBreakdown> categories;
  final double totalAmount;
  final Function(int categoryId)? onTap;

  // Use new business category colors

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty || totalAmount == 0) {
      return _buildEmptyState();
    }

    final List<PieChartSectionData> sections = _buildPieSections();

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 0,
          sectionsSpace: 2,
          startDegreeOffset: -90,
        ),
        duration: const Duration(milliseconds: 750),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final sumCategories = categories.fold<double>(
      0,
      (sum, cat) => sum + cat.totalAmount,
    );

    return categories.asMap().entries.map((entry) {
      final category = entry.value;
      final color = CategoryColors.forCategoryId(category.categoryId);
      final percentage = sumCategories > 0
          ? (category.totalAmount / sumCategories) * 100
          : 0;

      return PieChartSectionData(
        color: color,
        value: category.totalAmount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(category.categoryName, color: color, fontSize: 12),
        badgePositionPercentageOffset: 1.12,
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Swipe transactions to see your breakdown',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.color, required this.fontSize});

  final String label;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
