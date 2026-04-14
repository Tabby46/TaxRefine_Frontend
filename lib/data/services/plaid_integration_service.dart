import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/network/dio_client.dart';

enum PlaidLinkFlowStatus { linked, cancelled, failed }

typedef PlaidEventCallback =
    void Function(String eventName, Map<String, dynamic> metadata);

class PlaidIntegrationService {
  PlaidIntegrationService({
    required DioClient dioClient,
    required BuildContext context,
    Duration syncWaitDuration = const Duration(seconds: 3),
  }) : _dioClient = dioClient,
       _context = context,
       _syncWaitDuration = syncWaitDuration;

  final DioClient _dioClient;
  final BuildContext _context;
  final Duration _syncWaitDuration;
  bool _isLoaderVisible = false;

  Future<PlaidLinkFlowStatus> openPlaidLink(
    String userId, {
    ValueChanged<bool>? onSyncStateChanged,
    PlaidEventCallback? onEventTracked,
  }) async {
    if (userId.trim().isEmpty) {
      _showErrorDialog(AppStrings.plaidMissingUserId);
      return PlaidLinkFlowStatus.failed;
    }

    StreamSubscription? successSubscription;
    StreamSubscription? exitSubscription;
    StreamSubscription? eventSubscription;
    bool syncStateStarted = false;

    try {
      _showLoaderDialog(AppStrings.plaidPreparingLink);
      final linkToken = await _createLinkToken(userId);
      _hideLoaderDialog();

      await PlaidLink.create(
        configuration: LinkTokenConfiguration(token: linkToken),
      );

      final completer = Completer<_PlaidLinkOutcome>();

      successSubscription = PlaidLink.onSuccess.listen((event) {
        if (completer.isCompleted) {
          return;
        }

        final publicToken = _extractPublicToken(event);
        if (publicToken == null || publicToken.isEmpty) {
          completer.complete(
            _PlaidLinkOutcome.failure(AppStrings.plaidUnexpectedError),
          );
          return;
        }

        final metadata = _extractMetadataMap(event);
        final accounts = _extractAccountsFromMetadata(metadata);

        completer.complete(
          _PlaidLinkOutcome.success(
            publicToken: publicToken,
            accounts: accounts,
          ),
        );
      });

      exitSubscription = PlaidLink.onExit.listen((event) {
        if (completer.isCompleted) {
          return;
        }

        final metadata = _extractMetadataMap(event);
        final isCancelled = _isUserCancellation(event);

        onEventTracked?.call(
          isCancelled ? 'EXIT_CANCELLED' : 'EXIT_ERROR',
          metadata,
        );

        if (isCancelled) {
          completer.complete(
            _PlaidLinkOutcome.cancelled(_extractExitMessage(event)),
          );
        } else {
          completer.complete(
            _PlaidLinkOutcome.failure(_extractExitMessage(event)),
          );
        }
      });

      eventSubscription = PlaidLink.onEvent.listen((event) {
        final eventName = _extractEventName(event);
        final metadata = _extractMetadataMap(event);
        onEventTracked?.call(eventName, metadata);
      });

      PlaidLink.open();

      final outcome = await completer.future;

      if (outcome.status == PlaidLinkFlowStatus.cancelled) {
        _showSnackBar(outcome.message ?? AppStrings.plaidCancelled);
        return PlaidLinkFlowStatus.cancelled;
      }

      if (outcome.status == PlaidLinkFlowStatus.failed) {
        _showErrorDialog(outcome.message ?? AppStrings.plaidUnexpectedError);
        return PlaidLinkFlowStatus.failed;
      }

      _showLoaderDialog(AppStrings.plaidFinalizingLink);
      await _exchangePublicToken(
        userId: userId,
        publicToken: outcome.publicToken!,
        accounts: outcome.accounts,
      );
      await _triggerImmediateSync(userId);
      _hideLoaderDialog();

      onSyncStateChanged?.call(true);
      syncStateStarted = true;

      _showLoaderDialog(AppStrings.plaidSyncingData);
      await Future<void>.delayed(_syncWaitDuration);
      _hideLoaderDialog();

      onSyncStateChanged?.call(false);
      syncStateStarted = false;

      AuthSession.showDashboardRefreshHint = true;
      _showSnackBar(AppStrings.plaidLinkedSuccess);
      return PlaidLinkFlowStatus.linked;
    } on DioException catch (ex) {
      final message = ex.response?.data is Map<String, dynamic>
          ? (ex.response?.data['message'] as String? ??
                AppStrings.plaidNetworkError)
          : AppStrings.plaidNetworkError;
      _showErrorDialog(message);
      return PlaidLinkFlowStatus.failed;
    } catch (_) {
      _showErrorDialog(AppStrings.plaidUnexpectedError);
      return PlaidLinkFlowStatus.failed;
    } finally {
      _hideLoaderDialog();
      if (syncStateStarted) {
        onSyncStateChanged?.call(false);
      }
      await successSubscription?.cancel();
      await exitSubscription?.cancel();
      await eventSubscription?.cancel();
    }
  }

  Future<String> _createLinkToken(String userId) async {
    final response = await _dioClient.dio.post(
      '/plaid/create-link-token',
      options: Options(headers: {'X-User-Id': userId}),
      data: const {},
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid create-link-token response');
    }

    final linkToken = payload['linkToken'] as String?;
    if (linkToken == null || linkToken.isEmpty) {
      throw const FormatException(
        'linkToken missing in create-link-token response',
      );
    }

    return linkToken;
  }

  Future<void> _exchangePublicToken({
    required String userId,
    required String publicToken,
    required List<Map<String, dynamic>> accounts,
  }) async {
    await _dioClient.dio.post(
      '/plaid/exchange-token',
      options: Options(headers: {'X-User-Id': userId}),
      data: {'publicToken': publicToken, 'accounts': accounts},
    );
  }

  Future<void> _triggerImmediateSync(String userId) async {
    await _dioClient.dio.post(
      '/plaid/sync-now',
      options: Options(headers: {'X-User-Id': userId}),
      data: const {},
    );
  }

  String? _extractPublicToken(dynamic event) {
    final token = event.publicToken;
    if (token is String && token.isNotEmpty) {
      return token;
    }
    return null;
  }

  bool _isUserCancellation(dynamic event) {
    final error = event.error;
    if (error == null) {
      return true;
    }

    final errorCode = _safeRead<String>(() => error.errorCode) ?? '';
    final errorType = _safeRead<String>(() => error.errorType) ?? '';

    final normalizedCode = errorCode.toLowerCase();
    final normalizedType = errorType.toLowerCase();

    return normalizedCode.contains('user') &&
            normalizedCode.contains('cancel') ||
        normalizedType.contains('exit');
  }

  String _extractExitMessage(dynamic event) {
    final error = event.error;
    if (error == null) {
      return AppStrings.plaidCancelled;
    }

    final displayMessage = _safeRead<String>(() => error.displayMessage);
    if (displayMessage != null && displayMessage.isNotEmpty) {
      return displayMessage;
    }

    final errorMessage = _safeRead<String>(() => error.errorMessage);
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return errorMessage;
    }

    return AppStrings.plaidUnexpectedError;
  }

  String _extractEventName(dynamic event) {
    final name = _safeRead<String>(() => event.name);
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final eventName = _safeRead<String>(() => event.eventName);
    if (eventName != null && eventName.isNotEmpty) {
      return eventName;
    }

    return 'UNKNOWN_EVENT';
  }

  Map<String, dynamic> _extractMetadataMap(dynamic event) {
    final metadata = _safeRead<dynamic>(() => event.metadata);
    return _toJsonSafeMap(metadata);
  }

  List<Map<String, dynamic>> _extractAccountsFromMetadata(
    Map<String, dynamic> metadata,
  ) {
    final rawAccounts = metadata['accounts'];
    if (rawAccounts is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawAccounts.map<Map<String, dynamic>>((account) {
      final map = _toJsonSafeMap(account);

      if (map.isEmpty) {
        map['id'] = _safeRead<dynamic>(() => account.id)?.toString();
        map['account_id'] = _safeRead<dynamic>(() => account.id)?.toString();
        map['name'] = _safeRead<dynamic>(() => account.name)?.toString();
        map['mask'] = _safeRead<dynamic>(() => account.mask)?.toString();
        map['type'] = _safeRead<dynamic>(() => account.type)?.toString();
        map['subtype'] = _safeRead<dynamic>(() => account.subtype)?.toString();
        map.removeWhere((key, value) => value == null || value == '');
      }

      return map;
    }).toList();
  }

  Map<String, dynamic> _toJsonSafeMap(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, val) {
        out[key.toString()] = _toJsonSafeValue(val);
      });
      return out;
    }

    final toJsonMap = _safeRead<dynamic>(() => value.toJson());
    if (toJsonMap is Map) {
      return _toJsonSafeMap(toJsonMap);
    }

    return <String, dynamic>{};
  }

  dynamic _toJsonSafeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is List) {
      return value.map(_toJsonSafeValue).toList();
    }

    if (value is Map) {
      return _toJsonSafeMap(value);
    }

    final toJsonValue = _safeRead<dynamic>(() => value.toJson());
    if (toJsonValue != null) {
      return _toJsonSafeValue(toJsonValue);
    }

    return value.toString();
  }

  T? _safeRead<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(_context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorDialog(String message) {
    if (!_context.mounted) {
      return;
    }

    showDialog<void>(
      context: _context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.plaidErrorTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLoaderDialog(String message) {
    if (!_context.mounted || _isLoaderVisible) {
      return;
    }

    _isLoaderVisible = true;
    showDialog<void>(
      context: _context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoaderDialog() {
    if (!_isLoaderVisible || !_context.mounted) {
      return;
    }

    _isLoaderVisible = false;
    Navigator.of(_context, rootNavigator: true).pop();
  }
}

class _PlaidLinkOutcome {
  const _PlaidLinkOutcome._({
    required this.status,
    this.publicToken,
    this.accounts = const <Map<String, dynamic>>[],
    this.message,
  });

  final PlaidLinkFlowStatus status;
  final String? publicToken;
  final List<Map<String, dynamic>> accounts;
  final String? message;

  factory _PlaidLinkOutcome.success({
    required String publicToken,
    required List<Map<String, dynamic>> accounts,
  }) {
    return _PlaidLinkOutcome._(
      status: PlaidLinkFlowStatus.linked,
      publicToken: publicToken,
      accounts: accounts,
    );
  }

  factory _PlaidLinkOutcome.cancelled(String message) {
    return _PlaidLinkOutcome._(
      status: PlaidLinkFlowStatus.cancelled,
      message: message,
    );
  }

  factory _PlaidLinkOutcome.failure(String message) {
    return _PlaidLinkOutcome._(
      status: PlaidLinkFlowStatus.failed,
      message: message,
    );
  }
}
