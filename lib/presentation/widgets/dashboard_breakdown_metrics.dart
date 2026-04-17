import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/models/deduction_summary.dart';

class DashboardBreakdownMetrics extends StatelessWidget {
  const DashboardBreakdownMetrics({super.key, required this.summary});

  final DeductionSummary summary;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'As of Apr 6, 2025',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metrics cards
          _buildMetricCard(
            icon: '📊',
            color: const Color(0xFF0B6E4F),
            title: 'Taxable Income',
            amount: _formatCurrency(summary.totalDeductions * 5.4),
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            icon: '✓',
            color: const Color(0xFFF4A460),
            title: 'Deductions Claimed',
            amount: _formatCurrency(summary.totalDeductions),
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            icon: '⚠️',
            color: const Color(0xFFE91E63),
            title: 'Estimated Tax Owed',
            amount: _formatCurrency(summary.estimatedSavings * 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String icon,
    required Color color,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
