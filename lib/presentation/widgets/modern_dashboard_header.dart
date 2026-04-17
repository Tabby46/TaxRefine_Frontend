import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/models/deduction_summary.dart';
import 'package:taxrefine/core/models/category_breakdown.dart';
import 'package:taxrefine/presentation/widgets/deduction_pie_chart.dart';
import 'package:taxrefine/presentation/widgets/category_breakdown_list.dart';

class ModernDashboardHeader extends StatelessWidget {
  const ModernDashboardHeader({
    super.key,
    required this.summary,
    required this.categories,
  });

  final DeductionSummary? summary;
  final List<CategoryBreakdown> categories;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final totalDeductions = summary!.totalDeductions;
    final estimatedSavings = summary!.estimatedSavings;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estimated Savings Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B6E4F), Color(0xFF15A08C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B6E4F).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Tax Savings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatCurrency(estimatedSavings),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total Deductions: ${_formatCurrency(totalDeductions)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pie Chart Section
            Text(
              'Deduction Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DeductionPieChart(
              categories: categories,
              totalAmount: totalDeductions,
            ),
            const SizedBox(height: 32),

            // Category Breakdown List
            CategoryBreakdownList(categories: categories),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
