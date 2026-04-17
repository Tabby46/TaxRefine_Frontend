import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/history/history_state.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.categoryIdFilter});

  final int? categoryIdFilter;

  @override
  Widget build(BuildContext context) {
    final screenTitle = categoryIdFilter != null
        ? 'Category: ${_getCategoryName(categoryIdFilter!)}'
        : AppStrings.historyScreenTitle;

    return Scaffold(
      appBar: AppBar(title: Text(screenTitle)),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryInitial || state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as HistoryLoaded;
          final uploadingTransactionId = state is HistoryUploadingReceipt
              ? state.uploadingTransactionId
              : null;

          // Filter transactions by categoryId if filter is provided
          final filteredTransactions = categoryIdFilter != null
              ? loaded.transactions
                    .where((t) => t.categoryId == categoryIdFilter)
                    .toList()
              : loaded.transactions;

          if (filteredTransactions.isEmpty) {
            return const _HistoryEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().loadHistory(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                return _HistoryListTile(
                  transaction: transaction,
                  isUploadingReceipt: uploadingTransactionId == transaction.id,
                  onAttachMissingReceipt: () =>
                      _handleAttachMissingReceipt(context, transaction),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getCategoryName(int categoryId) {
    return switch (categoryId) {
      1 => 'Travel',
      2 => 'Meals',
      3 => 'Office Supplies',
      4 => 'Software',
      5 => 'Phone',
      6 => 'Internet',
      7 => 'Building',
      8 => 'Utilities',
      9 => 'Equipment',
      10 => 'Other Business',
      _ => 'Category $categoryId',
    };
  }

  Future<void> _handleAttachMissingReceipt(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final file = await _pickReceiptFile(context);
    if (file == null || !context.mounted) {
      return;
    }

    final cubit = context.read<HistoryCubit>();
    await cubit.attachReceiptLater(transactionId: transaction.id, file: file);

    if (!context.mounted) {
      return;
    }

    final current = cubit.state;
    if (current is HistoryLoaded) {
      TransactionModel? updated;
      for (final item in current.transactions) {
        if (item.id == transaction.id) {
          updated = item;
          break;
        }
      }
      final hasReceipt = (updated?.receiptDriveId ?? '').isNotEmpty;

      if (hasReceipt) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: const Text(AppStrings.receiptSecuredInDrive),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.shade700,
        content: const Text(AppStrings.receiptUploadFailed),
      ),
    );
  }

  Future<File?> _pickReceiptFile(BuildContext context) async {
    final source = await _selectImageSource(context);
    if (source == null) {
      return null;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 88,
    );

    if (picked == null) {
      return null;
    }
    return File(picked.path);
  }

  Future<ImageSource?> _selectImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text(AppStrings.takePhotoOption),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(AppStrings.uploadReceiptOption),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({
    required this.transaction,
    required this.onAttachMissingReceipt,
    this.isUploadingReceipt = false,
  });

  final TransactionModel transaction;
  final VoidCallback onAttachMissingReceipt;
  final bool isUploadingReceipt;

  @override
  Widget build(BuildContext context) {
    final date = transaction.transactionDate;
    final dateLabel = date != null
        ? DateFormat.yMMMd().add_jm().format(date)
        : '-';
    final amountLabel = NumberFormat.simpleCurrency().format(
      transaction.amount,
    );

    final isBusiness = transaction.isBusiness == true;
    final badgeLabel = isBusiness
        ? '${AppStrings.businessBadge} (+${(transaction.potentialTaxDeduction ?? 0).toStringAsFixed(2)})'
        : AppStrings.personalBadge;

    final badgeColor = isBusiness
        ? Colors.green.shade700
        : Colors.grey.shade600;
    final hasReceipt = (transaction.receiptDriveId ?? '').isNotEmpty;
    final isMissingReceipt = isBusiness && !hasReceipt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (hasReceipt)
                        IconButton(
                          tooltip: AppStrings.openReceiptFolderTooltip,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: const Icon(Icons.folder_open_rounded),
                          onPressed: () => _openReceiptInDrive(context),
                        ),
                      if (isMissingReceipt)
                        IconButton(
                          tooltip: AppStrings.missingReceiptTooltip,
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          icon: isUploadingReceipt
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                ),
                          onPressed: isUploadingReceipt
                              ? null
                              : onAttachMissingReceipt,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 90, maxWidth: 120),
              child: Text(
                amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReceiptInDrive(BuildContext context) async {
    final receiptDriveId = transaction.receiptDriveId;
    if (receiptDriveId == null || receiptDriveId.isEmpty) {
      return;
    }

    final uri = Uri.parse('https://drive.google.com/open?id=$receiptDriveId');
    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!didLaunch && context.mounted) {
      _showOpenLinkWarning(context);
    }
  }

  void _showOpenLinkWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.shade700,
        content: const Text(AppStrings.cannotOpenReceiptLink),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 52,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.noHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noHistorySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
