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
