import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/models/deduction_summary.dart';
import 'package:taxrefine/core/models/review_status.dart';
import 'package:taxrefine/presentation/widgets/review_status_pie_chart.dart';

class CompactDashboardHeader extends StatelessWidget {
  const CompactDashboardHeader({
    super.key,
    required this.summary,
    this.reviewStatus,
  });

  final DeductionSummary summary;
  final ReviewStatus? reviewStatus;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final estimatedSavings = summary.estimatedSavings;
    final totalDeductions = summary.totalDeductions;
    final reviewPercentage = summary.reviewProgressPercentage;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B6E4F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6E4F).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Metrics on left, Donut chart on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Estimated Tax Savings & Deductions (Flexible)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Tax Savings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: Text(
                          _formatCurrency(estimatedSavings),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Projected deductible value',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Total Deductions: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: _formatCurrency(totalDeductions),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Column: Review Status Donut Chart (Fixed Size)
                if (reviewStatus != null)
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ReviewStatusPieChart(reviewStatus: reviewStatus!),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Disclaimer text
            Text(
              'Numbers are estimates. Consult a tax professional for exact advice.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int reviewPercentage) {
    final progressValue = reviewPercentage / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$reviewPercentage% Reviewed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
