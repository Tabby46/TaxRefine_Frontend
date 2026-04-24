import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/network/dio_client.dart';

/// Handles the tax report CSV download from the backend export endpoint.
class ExportService {
  ExportService(this._dioClient);

  final DioClient _dioClient;

  /// Downloads the tax report CSV for the given [start]–[end] date range.
  ///
  /// Automatically calculates the device timezone offset (e.g. "+05:30") and
  /// sends it to the backend so the report's dates are always in local time.
  ///
  /// Returns the path to the saved file, ready for sharing.
  Future<String> downloadTaxReport(DateTime start, DateTime end) async {
    final rawUserId = AuthSession.userId;
    if (rawUserId == null || rawUserId.isEmpty) {
      throw StateError('User is not authenticated.');
    }

    // Normalize the userId to a UUID (backend expects UUID, not Google subject ID).
    final userId = ApiConstants.resolveUserId(rawUserId);

    final zoneOffset = _deviceZoneOffset();

    // Convert to UTC so the ISO string ends with 'Z' (no '+' sign).
    // A '+' in a query parameter is decoded as a space by Spring Boot's
    // form-url-encoding, which makes ZonedDateTime parsing fail (400).
    final startUtc = start.toUtc();
    final endUtc = DateTime(end.year, end.month, end.day, 23, 59, 59).toUtc();

    final startIso = startUtc.toIso8601String();
    final endIso = endUtc.toIso8601String();

    print(
      '[EXPORT] Requesting CSV: rawUserId=$rawUserId userId=$userId '
      'start=$startIso end=$endIso zoneOffset=$zoneOffset',
    );

    Response<List<int>> response;
    try {
      response = await _dioClient.dio.get<List<int>>(
        '/reports/export',
        queryParameters: {
          'userId': userId,
          'startDate': startIso,
          'endDate': endIso,
          'zoneOffset': zoneOffset,
        },
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final bodyRaw = e.response?.data;
      final body = bodyRaw is List<int>
          ? String.fromCharCodes(bodyRaw)
          : bodyRaw?.toString();
      print(
        '[EXPORT] DioException — type=${e.type.name} status=$status '
        'message=${e.message}',
      );
      if (body != null && body.isNotEmpty) {
        print('[EXPORT] Response body: $body');
      }
      rethrow;
    }

    print(
      '[EXPORT] Response OK: status=${response.statusCode} '
      'bytes=${response.data?.length ?? 0}',
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Export failed: server returned ${response.statusCode}.');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'tax_report_${start.year}-${_pad(start.month)}-${_pad(start.day)}'
        '_to_${end.year}-${_pad(end.month)}-${_pad(end.day)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.data!, flush: true);
    print('[EXPORT] File saved: ${file.path}');
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the current device timezone offset formatted as "+HH:MM" or "-HH:MM".
  String _deviceZoneOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
