import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/data/models/receipt_upload_result.dart';

class GoogleDriveProvider {
  GoogleDriveProvider({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static const String _folderName = 'TaxRefine_Receipts';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  Future<ReceiptUploadResult> uploadReceipt(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileHash = md5.convert(fileBytes).toString();

      final client = await _buildAuthenticatedClient();
      final driveApi = drive.DriveApi(client);
      final folderId = await _ensureReceiptFolder(driveApi);

      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final media = drive.Media(file.openRead(), await file.length());
      final metadata = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..appProperties = {'taxrefineManaged': 'true'};

      final uploaded = await driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id',
      );

      final fileId = uploaded.id;
      if (fileId == null || fileId.isEmpty) {
        throw const GoogleDriveUploadException(
          'Google Drive upload completed without a file id.',
        );
      }

      return ReceiptUploadResult(googleDriveFileId: fileId, fileHash: fileHash);
    } on GoogleSignInException {
      rethrow;
    } on GoogleDriveUploadException {
      rethrow;
    } catch (ex) {
      debugPrint('GoogleDriveProvider.uploadReceipt failed: $ex');
      throw GoogleDriveUploadException(_mapDriveError(ex));
    }
  }

  Future<String> _ensureReceiptFolder(drive.DriveApi driveApi) async {
    final existing = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id,name)',
      pageSize: 1,
    );

    final existingId = existing.files?.isNotEmpty == true
        ? existing.files!.first.id
        : null;
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..appProperties = {'taxrefineManaged': 'true'};

    final created = await driveApi.files.create(folder, $fields: 'id');
    final folderId = created.id;
    if (folderId == null || folderId.isEmpty) {
      throw const GoogleDriveUploadException(
        'Failed to create TaxRefine receipt folder.',
      );
    }

    return folderId;
  }

  Future<http.Client> _buildAuthenticatedClient() async {
    await _ensureInitialized();

    final account = await _googleSignIn.authenticate(scopeHint: _scopes);

    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );

    if (headers == null || !headers.containsKey('Authorization')) {
      throw const GoogleDriveUploadException(
        'Unable to obtain Google authorization headers.',
      );
    }

    return _GoogleAuthClient(headers);
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    final androidClientId = ApiConstants.googleAndroidClientId.trim();
    if (Platform.isAndroid || androidClientId.isEmpty) {
      await _googleSignIn.initialize(
        serverClientId: ApiConstants.googleServerClientId,
      );
    } else {
      await _googleSignIn.initialize(clientId: androidClientId);
    }
    _isInitialized = true;
  }

  String _mapDriveError(Object ex) {
    final message = ex.toString();
    final normalized = message.toLowerCase();

    if (normalized.contains('accessnotconfigured') ||
        normalized.contains('drive api has not been used') ||
        normalized.contains('api not enabled')) {
      return 'Google Drive API is not enabled for this Google project.';
    }

    if (normalized.contains('insufficient permissions') ||
        normalized.contains('insufficientpermission') ||
        normalized.contains('403')) {
      return 'Google Drive permission was denied. Please grant Drive access and try again.';
    }

    if (normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('timed out')) {
      return 'Network issue while uploading to Google Drive. Please retry.';
    }

    return 'Google Drive upload failed: $message';
  }
}

class GoogleDriveUploadException implements Exception {
  const GoogleDriveUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
