import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/core/models/bank_connection.dart';
import 'package:taxrefine/data/services/plaid_integration_service.dart';
import 'package:taxrefine/features/profile/cubit/bank_connection_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_state.dart';

class LinkedBanksScreen extends StatefulWidget {
  const LinkedBanksScreen({super.key});

  @override
  State<LinkedBanksScreen> createState() => _LinkedBanksScreenState();
}

class _LinkedBanksScreenState extends State<LinkedBanksScreen> {
  bool _isPlaidLinking = false;
  bool _isPlaidSyncing = false;

  @override
  void initState() {
    super.initState();
    context.read<BankConnectionCubit>().loadConnections();
  }

  Future<void> _pollPendingTransactionsAfterLink() async {
    final cubit = context.read<TransactionCubit>();
    const maxAttempts = 6;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await cubit.loadPendingTransactions();
      final currentState = cubit.state;

      if (currentState is TransactionLoaded &&
          currentState.transactions.isNotEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.swipeSyncCompleted)),
        );
        return;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.swipeSyncStillRunning)),
    );
  }

  Future<void> _connectBankAccount() async {
    if (_isPlaidLinking) {
      return;
    }

    setState(() {
      _isPlaidLinking = true;
    });

    final userId = ApiConstants.resolveUserId(AuthSession.userId);
    final plaidService = PlaidIntegrationService(
      dioClient: DioClient(),
      context: context,
    );

    final status = await plaidService.openPlaidLink(
      userId,
      onSyncStateChanged: (isSyncing) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isPlaidSyncing = isSyncing;
        });
      },
      onEventTracked: (eventName, metadata) {
        debugPrint('Plaid event: $eventName | metadata: $metadata');
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPlaidLinking = false;
    });

    if (status == PlaidLinkFlowStatus.linked) {
      if (mounted) {
        context.read<HistoryCubit>().loadHistory();
        context.read<BankConnectionCubit>().loadConnections();
        setState(() => _isPlaidSyncing = true);
        await _pollPendingTransactionsAfterLink();
        if (!mounted) {
          return;
        }
        setState(() => _isPlaidSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.dashboardRefreshBannerMessage),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Linked Banks'), centerTitle: true),
      body: BlocBuilder<BankConnectionCubit, BankConnectionState>(
        builder: (context, state) {
          if (state is BankConnectionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BankConnectionError) {
            return _ErrorState(message: state.message);
          }

          if (state is BankConnectionLoaded) {
            if (state.connections.isEmpty) {
              return const _EmptyState();
            }

            return _BankConnectionsList(connections: state.connections);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPlaidLinking ? null : _connectBankAccount,
        icon: _isPlaidLinking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(Icons.add),
        label: const Text('Link New Bank'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No banks connected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your bank accounts to automatically import transactions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Pass context down to state
                context
                    .findAncestorStateOfType<_LinkedBanksScreenState>()
                    ?._connectBankAccount();
              },
              icon: const Icon(Icons.add),
              label: const Text('Link Your First Bank'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load connections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<BankConnectionCubit>().loadConnections();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankConnectionsList extends StatelessWidget {
  final List<BankConnection> connections;

  const _BankConnectionsList({required this.connections});

  @override
  Widget build(BuildContext context) {
    final bankConnectionCubit = context.read<BankConnectionCubit>();
    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      itemCount: connections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final connection = connections[index];
        return _BankConnectionCard(
          connection: connection,
          bankConnectionCubit: bankConnectionCubit,
        );
      },
    );
  }
}

class _BankConnectionCard extends StatelessWidget {
  final BankConnection connection;
  final BankConnectionCubit bankConnectionCubit;

  const _BankConnectionCard({
    required this.connection,
    required this.bankConnectionCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.institutionName ?? 'Unknown Bank',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connection.lastSynced != null
                        ? 'Last synced: ${DateFormat.yMMMd().add_jm().format(connection.lastSynced!)}'
                        : 'Not synced yet',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${connection.transactionCount} transactions',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                _StatusBadge(isActive: connection.isActive),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () =>
                      _showUnlinkDialog(context, bankConnectionCubit),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Unlink bank',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlinkDialog(
    BuildContext context,
    BankConnectionCubit bankConnectionCubit,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bankConnectionCubit,
        child: AlertDialog(
          title: const Text('Unlink Bank'),
          content: Text(
            'Are you sure you want to unlink ${connection.institutionName ?? 'this bank'}? All synced transactions will be removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bankConnectionCubit.unlinkBank(connection.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Unlink'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Error',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }
}
