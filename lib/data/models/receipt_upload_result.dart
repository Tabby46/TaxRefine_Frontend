class ReceiptUploadResult {
  const ReceiptUploadResult({
    required this.googleDriveFileId,
    required this.fileHash,
  });

  final String googleDriveFileId;
  final String fileHash;
}
