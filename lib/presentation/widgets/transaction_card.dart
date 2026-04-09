import 'package:flutter/material.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/data/models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    required this.onAttachReceipt,
    this.isUploadingReceipt = false,
    super.key,
  });

  final TransactionModel transaction;
  final VoidCallback onAttachReceipt;
  final bool isUploadingReceipt;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.merchantName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: AppStrings.uploadReceiptTooltip,
                icon: isUploadingReceipt
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                onPressed: isUploadingReceipt ? null : onAttachReceipt,
              ),
            ),
            if (isUploadingReceipt)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
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
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              currency.format(transaction.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.swipeHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
