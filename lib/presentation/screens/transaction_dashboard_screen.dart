import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/models/transaction_model.dart';
import 'package:taxrefine/data/models/transaction_page_result.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';

class TransactionDashboardScreen extends StatefulWidget {
  const TransactionDashboardScreen({super.key});

  @override
  State<TransactionDashboardScreen> createState() =>
      _TransactionDashboardScreenState();
}

class _TransactionDashboardScreenState extends State<TransactionDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  late final TransactionApiProvider _apiProvider;

  final List<TransactionModel> _transactions = [];
  _DashboardFilter _filter = _DashboardFilter.all;

  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final Set<String> _updatingTransactionIds = <String>{};
  late final AnimationController _pullHintController;

  @override
  void initState() {
    super.initState();
    _apiProvider = TransactionApiProvider(DioClient());
    _pullHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showRefreshHintIfNeeded(),
    );
    _loadFirstPage();
  }

  @override
  void dispose() {
    _pullHintController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _currentPage = 0;
      _isLastPage = false;
      _isInitialLoading = true;
      _errorMessage = null;
      _transactions.clear();
    });

    await _loadPage(reset: true);
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoadingMore || (_isLastPage && !reset)) {
      return;
    }

    if (!reset) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final userId = ApiConstants.resolveUserId(AuthSession.userId);
      final response = await _apiProvider.fetchUserTransactionsPage(
        userId: userId,
        taxCategory: _filter.taxCategoryQuery,
        page: _currentPage,
        size: _pageSize,
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Invalid page response');
      }

      final pageResult = TransactionPageResult.fromJson(payload);

      setState(() {
        _transactions.addAll(pageResult.transactions);
        _isLastPage = pageResult.last;
        _currentPage += 1;
        _errorMessage = null;
      });
    } on DioException catch (ex) {
      setState(() {
        _errorMessage = _resolveLoadError(ex);
      });
    } catch (_) {
      setState(() {
        _errorMessage = AppStrings.loadingTransactionsFailed;
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadPage();
    }
  }

  Future<void> _onRefresh() async {
    await _loadFirstPage();
  }

  void _showRefreshHintIfNeeded() {
    if (!mounted || !AuthSession.showDashboardRefreshHint) {
      return;
    }

    AuthSession.showDashboardRefreshHint = false;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: const Text(AppStrings.dashboardRefreshBannerMessage),
        leading: const Icon(Icons.sync),
        backgroundColor: Colors.blueGrey.shade50,
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text(AppStrings.dashboardRefreshNowAction),
          ),
        ],
      ),
    );
  }

  void _onFilterSelected(_DashboardFilter filter) {
    if (_filter == filter) {
      return;
    }

    setState(() {
      _filter = filter;
    });

    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.transactionDashboardTitle)),
      body: Column(
        children: [
          _buildFilterRow(),
          _buildPullHint(),
          Expanded(child: _buildListBody()),
        ],
      ),
    );
  }

  Widget _buildPullHint() {
    return AnimatedBuilder(
      animation: _pullHintController,
      builder: (context, child) {
        final dy = -4 * _pullHintController.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.south_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.dashboardPullHint,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: _DashboardFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: _filter == filter,
              onSelected: (_) => _onFilterSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF0B6E4F),
        displacement: 30,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadFirstPage,
                      child: const Text(AppStrings.retryAction),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF0B6E4F),
        displacement: 30,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 360,
              child: Center(child: Text(AppStrings.noHistory)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF0B6E4F),
      displacement: 30,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _transactions.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _transactions.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final transaction = _transactions[index];
          return _DashboardTransactionTile(
            transaction: transaction,
            isUpdating: _updatingTransactionIds.contains(transaction.id),
            onMarkBusiness: () => _handleSwipeAction(transaction, 'BUSINESS'),
            onMarkPersonal: () => _handleSwipeAction(transaction, 'PERSONAL'),
          );
        },
      ),
    );
  }

  String _resolveLoadError(DioException ex) {
    if (ex.type == DioExceptionType.connectionError ||
        ex.type == DioExceptionType.connectionTimeout ||
        ex.type == DioExceptionType.receiveTimeout ||
        ex.response?.statusCode == null) {
      return AppStrings.dashboardServerUnavailable;
    }
    return AppStrings.loadingTransactionsFailed;
  }

  Future<void> _handleSwipeAction(
    TransactionModel transaction,
    String targetCategory,
  ) async {
    if (_updatingTransactionIds.contains(transaction.id)) {
      return;
    }

    final originalIndex = _transactions.indexWhere(
      (t) => t.id == transaction.id,
    );
    if (originalIndex == -1) {
      return;
    }

    final originalItem = _transactions[originalIndex];
    final shouldRemoveOptimistically = _filter == _DashboardFilter.needsReview;

    setState(() {
      _updatingTransactionIds.add(transaction.id);

      if (shouldRemoveOptimistically) {
        _transactions.removeAt(originalIndex);
      } else {
        _transactions[originalIndex] = _transactions[originalIndex].copyWith(
          taxCategory: targetCategory,
          isBusiness: targetCategory == 'BUSINESS'
              ? true
              : targetCategory == 'PERSONAL'
              ? false
              : _transactions[originalIndex].isBusiness,
        );
      }
    });

    try {
      await _apiProvider.updateTransactionTaxCategory(
        transactionId: transaction.id,
        taxCategory: targetCategory,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetCategory == 'BUSINESS'
                ? AppStrings.dashboardMarkedBusiness
                : AppStrings.dashboardMarkedPersonal,
          ),
        ),
      );

      if (shouldRemoveOptimistically && !_isLastPage) {
        await _loadPage();
      }
    } on DioException {
      if (!mounted) {
        return;
      }

      setState(() {
        if (shouldRemoveOptimistically) {
          final reinsertionIndex = originalIndex.clamp(0, _transactions.length);
          _transactions.insert(reinsertionIndex, originalItem);
        } else {
          final currentIndex = _transactions.indexWhere(
            (t) => t.id == originalItem.id,
          );
          if (currentIndex != -1) {
            _transactions[currentIndex] = originalItem;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.dashboardSwipeFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingTransactionIds.remove(transaction.id);
        });
      }
    }
  }
}

class _DashboardTransactionTile extends StatelessWidget {
  const _DashboardTransactionTile({
    required this.transaction,
    required this.isUpdating,
    required this.onMarkBusiness,
    required this.onMarkPersonal,
  });

  final TransactionModel transaction;
  final bool isUpdating;
  final Future<void> Function() onMarkBusiness;
  final Future<void> Function() onMarkPersonal;

  @override
  Widget build(BuildContext context) {
    final dateLabel = transaction.transactionDate == null
        ? '-'
        : DateFormat.yMMMd().format(transaction.transactionDate!);
    final amountLabel = NumberFormat.simpleCurrency().format(
      transaction.amount,
    );

    final normalizedCategory = _normalizedCategory(transaction);
    final badgeColor = _badgeColor(normalizedCategory);

    return Slidable(
      enabled: !isUpdating,
      key: ValueKey(transaction.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: () => onMarkBusiness()),
        children: [
          SlidableAction(
            onPressed: (_) => onMarkBusiness(),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            icon: Icons.business_center,
            label: 'BUSINESS',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: () => onMarkPersonal()),
        children: [
          SlidableAction(
            onPressed: (_) => onMarkPersonal(),
            backgroundColor: Colors.blueGrey.shade600,
            foregroundColor: Colors.white,
            icon: Icons.person,
            label: 'PERSONAL',
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          transaction.merchantName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(dateLabel),
        trailing: isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
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
                      normalizedCategory,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _normalizedCategory(TransactionModel model) {
    final taxCategory = model.taxCategory;
    if (taxCategory != null && taxCategory.trim().isNotEmpty) {
      return taxCategory.trim().toUpperCase();
    }
    if (model.isBusiness == true) {
      return 'BUSINESS';
    }
    if (model.isBusiness == false) {
      return 'PERSONAL';
    }
    return 'UNCLASSIFIED';
  }

  Color _badgeColor(String category) {
    switch (category) {
      case 'NEEDS_REVIEW':
        return Colors.orange.shade700;
      case 'BUSINESS':
        return Colors.green.shade700;
      case 'PERSONAL':
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

enum _DashboardFilter {
  all(label: 'All', taxCategoryQuery: null),
  needsReview(label: 'Needs Review', taxCategoryQuery: 'NEEDS_REVIEW'),
  business(label: 'Business', taxCategoryQuery: 'BUSINESS'),
  personal(label: 'Personal', taxCategoryQuery: 'PERSONAL');

  const _DashboardFilter({required this.label, required this.taxCategoryQuery});

  final String label;
  final String? taxCategoryQuery;
}
