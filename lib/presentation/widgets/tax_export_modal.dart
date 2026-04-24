import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taxrefine/logic/export/export_service.dart';

/// A bottom-sheet modal that lets the user pick a date range and export their
/// business transactions as a tax-ready CSV file.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => TaxExportModal(exportService: exportService),
/// );
/// ```
class TaxExportModal extends StatefulWidget {
  const TaxExportModal({super.key, required this.exportService});

  final ExportService exportService;

  @override
  State<TaxExportModal> createState() => _TaxExportModalState();
}

class _TaxExportModalState extends State<TaxExportModal> {
  DateTimeRange? _selectedRange;
  bool _isLoading = false;
  String? _errorMessage;

  final DateFormat _fmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.file_download_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Export Tax Report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a date range and export your business transactions as a '
            'CSV file you can share with your accountant.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Your report will be generated as a CSV file compatible with Excel and Google Sheets.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),

          // ── Date Range Picker ────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isLoading ? null : _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedRange != null
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedRange == null
                        ? 'Select date range…'
                        : '${_fmt.format(_selectedRange!.start)}  →  '
                              '${_fmt.format(_selectedRange!.end)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _selectedRange != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Error ────────────────────────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Export Button ────────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: (_isLoading || _selectedRange == null)
                ? null
                : _exportCsv,
            icon: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(_isLoading ? 'Generating…' : 'Export & Share CSV'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange:
          _selectedRange ??
          DateTimeRange(start: DateTime(now.year, 1, 1), end: now),
      helpText: 'SELECT REPORT PERIOD',
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final filePath = await widget.exportService.downloadTaxReport(
        _selectedRange!.start,
        _selectedRange!.end,
      );
      if (!mounted) return;
      // Dismiss the modal before opening the share sheet.
      Navigator.pop(context);
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Tax Report — TaxRefine',
        text: 'Please find my tax report CSV attached. Generated by TaxRefine.',
      );
    } catch (e, stack) {
      print('[EXPORT_MODAL] Export error: $e');
      print('[EXPORT_MODAL] Stack: $stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      print(
        '[EXPORT_MODAL] DioException type=${e.type.name} '
        'status=${e.response?.statusCode}',
      );
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please try again.';
        case DioExceptionType.connectionError:
          return 'Could not reach the server. Check your connection and try again.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 400)
            return 'Invalid export request. Please try a different date range.';
          if (status == 401 || status == 403)
            return 'Session expired. Please sign in again.';
          if (status != null && status >= 500) {
            return 'The server encountered an error. Please try again shortly.';
          }
          return 'Export failed (HTTP $status). Please try again.';
        default:
          break;
      }
    }
    final raw = e.toString();
    if (raw.contains('SocketException') || raw.contains('Connection refused')) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    if (raw.contains('401') || raw.contains('403')) {
      return 'Session expired. Please sign in again.';
    }
    if (raw.contains('500')) {
      return 'The server encountered an error. Please try again shortly.';
    }
    return 'Export failed. Please try again.';
  }
}
