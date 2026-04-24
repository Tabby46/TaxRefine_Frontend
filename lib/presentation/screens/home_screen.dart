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
import 'package:taxrefine/data/models/categorization_rule_model.dart';
import 'package:taxrefine/data/providers/categorization_rule_api_provider.dart';
import 'package:taxrefine/presentation/widgets/category_selection_dialog.dart';
import 'package:taxrefine/presentation/widgets/rule_prompt_bottom_sheet.dart';
import 'package:taxrefine/presentation/widgets/transaction_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlaidLinking = false;
  bool _isPlaidSyncing = false;

  late final CategorizationRuleApiProvider _ruleProvider;
  final Set<String> _merchantsWithRules = <String>{};

  @override
  void initState() {
    super.initState();
    _ruleProvider = CategorizationRuleApiProvider(DioClient());
  }

  Future<void> _playSwipeFeedback(CardSwiperDirection direction) async {
    await SystemSound.play(SystemSoundType.click);

    if (direction == CardSwiperDirection.right) {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 42));
      await HapticFeedback.lightImpact();
      return;
    }

    if (direction == CardSwiperDirection.left) {
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 36));
      await HapticFeedback.selectionClick();
    }
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

                                  // Animate neon border based on swipe direction and intensity
                                  String? swipeDirection;
                                  double borderGlow = 0.0;
                                  if (horizontalThresholdPercentage.abs() > 2) {
                                    if (horizontalThresholdPercentage > 0) {
                                      swipeDirection = 'right';
                                      borderGlow =
                                          (horizontalThresholdPercentage /
                                                  100.0)
                                              .clamp(0.0, 1.0);
                                    } else if (horizontalThresholdPercentage <
                                        0) {
                                      swipeDirection = 'left';
                                      borderGlow =
                                          (-horizontalThresholdPercentage /
                                                  100.0)
                                              .clamp(0.0, 1.0);
                                    }
                                  }

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
                                    swipeDirection: swipeDirection,
                                    borderGlow: borderGlow,
                                  );
                                },
                            onSwipe:
                                (previousIndex, currentIndex, direction) async {
                                  if (direction == CardSwiperDirection.right) {
                                    final cubit = context
                                        .read<TransactionCubit>();
                                    // Capture the transaction before the swipe
                                    // removes it from the cubit's list.
                                    final transaction =
                                        loaded.transactions[previousIndex];
                                    final receiptFile = await _pickReceiptFile(
                                      context,
                                    );

                                    if (!context.mounted) return false;

                                    // Show category selection dialog
                                    final selectedCategoryId =
                                        await showDialog<int?>(
                                          context: context,
                                          builder: (context) =>
                                              const CategorySelectionDialog(),
                                        );

                                    if (selectedCategoryId == null) {
                                      // User cancelled category selection
                                      return false;
                                    }

                                    await _playSwipeFeedback(direction);
                                    final success = await cubit.swipe(
                                      isBusiness: true,
                                      categoryId: selectedCategoryId,
                                      swipedIndex: previousIndex,
                                      receiptFile: receiptFile,
                                    );

                                    // Offer to create a Smart Rule after a
                                    // successful business swipe.
                                    if (success &&
                                        mounted &&
                                        !_merchantsWithRules.contains(
                                          transaction.merchantName,
                                        )) {
                                      await _showRulePromptIfNeeded(
                                        merchantName: transaction.merchantName,
                                        categoryId: selectedCategoryId,
                                      );
                                    }

                                    return success;
                                  }
                                  if (direction == CardSwiperDirection.left) {
                                    final cubit = context
                                        .read<TransactionCubit>();
                                    await _playSwipeFeedback(direction);
                                    return cubit.swipe(
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

  Future<void> _showRulePromptIfNeeded({
    required String merchantName,
    required int categoryId,
  }) async {
    if (!mounted) return;
    final userId = ApiConstants.resolveUserId(AuthSession.userId);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RulePromptBottomSheet(
        merchantName: merchantName,
        categoryId: categoryId,
        userId: userId,
        ruleProvider: _ruleProvider,
        onRuleCreated: (CategorizationRuleModel? rule) {
          if (rule != null) {
            _merchantsWithRules.add(merchantName);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Rule saved — future "$merchantName" transactions will be auto-categorized.',
                  ),
                  backgroundColor: const Color(0xFF0B6E4F),
                ),
              );
            }
          }
        },
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
