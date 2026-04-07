import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/history/history_state.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyScreenTitle)),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryInitial || state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as HistoryLoaded;
          if (loaded.transactions.isEmpty) {
            return const _HistoryEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HistoryCubit>().loadHistory(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: loaded.transactions.length,
              itemBuilder: (context, index) {
                final transaction = loaded.transactions[index];
                return _HistoryListTile(transaction: transaction);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({required this.transaction});

  final TransactionModel transaction;

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(transaction.merchantName),
        subtitle: Text(dateLabel),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amountLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                if ((transaction.receiptDriveId ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
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
                ],
              ],
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
