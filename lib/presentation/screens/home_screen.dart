import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/services/plaid_integration_service.dart';
import 'package:taxrefine/logic/dashboard/dashboard_summary_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_state.dart';
import 'package:taxrefine/presentation/widgets/category_selection_dialog.dart';
import 'package:taxrefine/presentation/widgets/transaction_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlaidLinking = false;
  bool _isPlaidSyncing = false;

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
      context.read<HistoryCubit>().loadHistory();
      setState(() => _isPlaidSyncing = true);
      await _pollPendingTransactionsAfterLink();
      if (!mounted) {
        return;
      }
      setState(() => _isPlaidSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.dashboardRefreshBannerMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.swipeScreenTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.plaidConnectTooltip,
            icon: _isPlaidLinking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.account_balance),
            onPressed: _isPlaidLinking ? null : _connectBankAccount,
          ),
        ],
      ),
      body: BlocListener<TransactionCubit, TransactionState>(
        listenWhen: (previous, current) {
          if (current is! TransactionLoaded) {
            return false;
          }
          if (previous is! TransactionLoaded) {
            return current.feedbackMessage != null;
          }
          return previous.feedbackToken != current.feedbackToken &&
              current.feedbackMessage != null;
        },
        listener: (context, state) {
          if (state is TransactionLoaded && state.feedbackMessage != null) {
            if (state.feedbackType == TransactionFeedbackType.info) {
              context.read<HistoryCubit>().loadHistory();
            }

            // Refresh the dashboard summary after any successful swipe
            final userId = ApiConstants.resolveUserId(AuthSession.userId);
            context.read<DashboardSummaryCubit>().refreshSummary(userId);

            final isSuccess =
                state.feedbackType == TransactionFeedbackType.success;

            if (isSuccess) {
              HapticFeedback.vibrate();
            }

            final backgroundColor =
                state.feedbackType == TransactionFeedbackType.warning
                ? Colors.orange.shade700
                : Colors.green.shade700;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: backgroundColor,
                content: Text(state.feedbackMessage!),
              ),
            );
          }
        },
        child: BlocBuilder<TransactionCubit, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading || state is TransactionInitial) {
              return const _TransactionLoadingShimmer();
            }

            if (state is TransactionError) {
              return Center(child: Text(state.message));
            }

            final loaded = state as TransactionLoaded;
            final isUploading = state is TransactionUploadingReceipt;
            if (loaded.transactions.isEmpty) {
              return const Center(
                child: Text(AppStrings.noPendingTransactions),
              );
            }

            return Column(
              children: [
                if (_isPlaidSyncing)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    semanticsLabel: AppStrings.plaidSyncingData,
                  ),
                if (isUploading) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth < 420
                          ? 12.0
                          : 24.0;
                      final cardHeight = (constraints.maxHeight * 0.72).clamp(
                        260.0,
                        520.0,
                      );

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        child: SizedBox(
                          height: cardHeight,
                          child: CardSwiper(
                            key: ValueKey(
                              'swiper-${loaded.transactions.length}-${loaded.transactions.first.id}',
                            ),
                            cardsCount: loaded.transactions.length,
                            numberOfCardsDisplayed: loaded.transactions.length
                                .clamp(1, 3),
                            cardBuilder:
                                (
                                  BuildContext context,
                                  int index,
                                  int horizontalThresholdPercentage,
                                  int verticalThresholdPercentage,
                                ) {
                                  if (index < 0 ||
                                      index >= loaded.transactions.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final transaction =
                                      loaded.transactions[index];
                                  final uploadingThisCard =
                                      state is TransactionUploadingReceipt &&
                                      state.uploadingTransactionId ==
                                          transaction.id;

                                  return TransactionCard(
                                    transaction: transaction,
                                    isUploadingReceipt: uploadingThisCard,
                                    onAttachReceipt: () async {
                                      final cubit = context
                                          .read<TransactionCubit>();
                                      final file = await _pickReceiptFile(
                                        context,
                                      );
                                      if (file == null) {
                                        return;
                                      }
                                      await cubit.uploadReceiptAndSync(
                                        transaction: transaction,
                                        file: file,
                                      );
                                    },
                                  );
                                },
                            onSwipe:
                                (previousIndex, currentIndex, direction) async {
                                  if (direction == CardSwiperDirection.right) {
                                    final cubit = context
                                        .read<TransactionCubit>();
                                    final receiptFile = await _pickReceiptFile(
                                      context,
                                    );
                                    
                                    if (!mounted) return false;
                                    
                                    // Show category selection dialog
                                    final selectedCategoryId = await showDialog<int?>(
                                      context: context,
                                      builder: (context) =>
                                          const CategorySelectionDialog(),
                                    );
                                    
                                    if (selectedCategoryId == null) {
                                      // User cancelled category selection
                                      return false;
                                    }
                                    
                                    return cubit.swipe(
                                      isBusiness: true,
                                      categoryId: selectedCategoryId,
                                      swipedIndex: previousIndex,
                                      receiptFile: receiptFile,
                                    );
                                  }
                                  if (direction == CardSwiperDirection.left) {
                                    return context
                                        .read<TransactionCubit>()
                                        .swipe(
                                          isBusiness: false,
                                          swipedIndex: previousIndex,
                                        );
                                  }
                                  return false;
                                },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
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

class _TransactionLoadingShimmer extends StatelessWidget {
  const _TransactionLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}
