import 'package:flutter/material.dart';
import 'package:taxrefine/data/models/categorization_rule_model.dart';
import 'package:taxrefine/data/providers/categorization_rule_api_provider.dart';

/// Bottom sheet shown after a manual BUSINESS swipe when no rule exists for a merchant.
/// Lets the user choose to categorize just this transaction or always for this merchant.
class RulePromptBottomSheet extends StatefulWidget {
  const RulePromptBottomSheet({
    super.key,
    required this.merchantName,
    required this.categoryId,
    required this.userId,
    required this.ruleProvider,
    required this.onRuleCreated,
  });

  final String merchantName;
  final int categoryId;
  final String userId;
  final CategorizationRuleApiProvider ruleProvider;

  /// Called with the created rule (or null if "Just this once" is selected).
  final void Function(CategorizationRuleModel? rule) onRuleCreated;

  @override
  State<RulePromptBottomSheet> createState() => _RulePromptBottomSheetState();
}

class _RulePromptBottomSheetState extends State<RulePromptBottomSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleAlways() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rule = await widget.ruleProvider.createRule(
        CategorizationRuleModel(
          userId: widget.userId,
          merchantName: widget.merchantName,
          categoryId: widget.categoryId,
        ),
        bulkApply: true,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onRuleCreated(rule);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not save rule. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF0B6E4F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Smart Rule',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You marked "${widget.merchantName}" as Business.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Would you like to always categorize this merchant as Business?',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Updating historical transactions…',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onRuleCreated(null);
                      },
                      child: const Text('Just this once'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleAlways,
                      icon: const Icon(Icons.rule, size: 18),
                      label: const Text('Always'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B6E4F),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
