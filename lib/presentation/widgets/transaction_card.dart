import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taxrefine/core/constants/app_strings.dart';

import 'package:taxrefine/core/theme/app_theme.dart';

import 'package:intl/intl.dart';

import 'package:taxrefine/data/models/transaction_model.dart';

class TransactionCard extends StatefulWidget {
  const TransactionCard({
    required this.transaction,

    required this.onAttachReceipt,

    this.isUploadingReceipt = false,

    this.borderGlow = 0.3,

    this.swipeDirection,

    super.key,
  });

  final TransactionModel transaction;

  final VoidCallback onAttachReceipt;

  final bool isUploadingReceipt;

  final double borderGlow; // 0.0 - 1.0

  final String? swipeDirection; // 'left', 'right', or null

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  String? _lastPrimedDirection;

  @override
  void didUpdateWidget(covariant TransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final direction = widget.swipeDirection;
    final crossedPrimeThreshold =
        widget.borderGlow >= 0.35 && oldWidget.borderGlow < 0.35;

    if (direction == null || widget.borderGlow < 0.08) {
      _lastPrimedDirection = null;
      return;
    }

    if (crossedPrimeThreshold && _lastPrimedDirection != direction) {
      _lastPrimedDirection = direction;
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // Neon glow intensity for border
    final double leftGlow = widget.swipeDirection == 'left'
        ? widget.borderGlow
        : 0.12;
    final double rightGlow = widget.swipeDirection == 'right'
        ? widget.borderGlow
        : 0.12;
    // Reduce top/bottom glow area by 50%
    const double verticalGlowAreaFactor = 0.5;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,

      height: MediaQuery.of(context).size.height * 0.6,

      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          // Blue Neon Glow: left edge
          BoxShadow(
            color: NeonColors.personalBlue.withOpacity(
              isDark ? 0.38 * (0.5 + leftGlow) : 0.18 * (0.5 + leftGlow),
            ),
            blurRadius: 32 * (0.5 + leftGlow),
            offset: const Offset(-8, 0),
            spreadRadius: 1,
          ),
          // Blue Neon Glow: bottom-left (reduce area by 50%)
          BoxShadow(
            color: NeonColors.personalBlue.withOpacity(
              isDark ? 0.32 * (0.5 + leftGlow) : 0.12 * (0.5 + leftGlow),
            ),
            blurRadius: 24 * (0.5 + leftGlow), // 50% of previous 48
            offset: const Offset(-8, 12), // 50% of previous 24
            spreadRadius: 1, // 50% of previous 2
          ),
          // Green Neon Glow: right edge
          BoxShadow(
            color: NeonColors.businessGreen.withOpacity(
              isDark ? 0.38 * (0.5 + rightGlow) : 0.18 * (0.5 + rightGlow),
            ),
            blurRadius: 32 * (0.5 + rightGlow),
            offset: const Offset(8, 0),
            spreadRadius: 1,
          ),
          // Green Neon Glow: top-right (reduce area by 50%)
          BoxShadow(
            color: NeonColors.businessGreen.withOpacity(
              isDark ? 0.32 * (0.5 + rightGlow) : 0.12 * (0.5 + rightGlow),
            ),
            blurRadius: 24 * (0.5 + rightGlow), // 50% of previous 48
            offset: const Offset(8, -12), // 50% of previous -24
            spreadRadius: 1, // 50% of previous 2
          ),
          // Subtle shadow for card
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.7)
                : Colors.grey.withOpacity(0.10),
            blurRadius: isDark ? 32 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Stack(
        children: [
          // Top labels and arrows
          Positioned(
            top: 12,

            left: 0,

            right: 0,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                // Personal (left)
                Padding(
                  padding: const EdgeInsets.only(left: 8),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      RotatedBox(
                        quarterTurns: 3,

                        child: Text(
                          'PERSONAL',

                          style: theme.textTheme.labelLarge?.copyWith(
                            color: NeonColors.personalBlue,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      Icon(
                        Icons.arrow_left,

                        color: NeonColors.personalBlue,

                        size: 22,
                      ),
                    ],
                  ),
                ),

                // Business (right)
                Padding(
                  padding: const EdgeInsets.only(right: 8),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Icon(
                        Icons.arrow_right,

                        color: NeonColors.businessGreen,

                        size: 22,
                      ),

                      const SizedBox(width: 4),

                      RotatedBox(
                        quarterTurns: 1,

                        child: Text(
                          'BUSINESS',

                          style: theme.textTheme.labelLarge?.copyWith(
                            color: NeonColors.businessGreen,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  widget.transaction.merchantName,

                  style: theme.textTheme.headlineSmall,
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,

                  child: IconButton(
                    tooltip: AppStrings.uploadReceiptTooltip,

                    icon: widget.isUploadingReceipt
                        ? const SizedBox(
                            width: 20,

                            height: 20,

                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),

                    onPressed: widget.isUploadingReceipt
                        ? null
                        : widget.onAttachReceipt,
                  ),
                ),

                if (widget.isUploadingReceipt)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,

                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),

                      borderRadius: BorderRadius.circular(999),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const SizedBox(
                          width: 14,

                          height: 14,

                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          AppStrings.uploadingToDrive,

                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                Text(
                  currency.format(widget.transaction.amount),

                  style: theme.textTheme.titleLarge?.copyWith(
                    color: NeonColors.businessGreen,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Text(AppStrings.swipeHint, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
