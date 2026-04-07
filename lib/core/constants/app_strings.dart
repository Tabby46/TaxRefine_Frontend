class AppStrings {
  static const appTitle = 'TaxRefine';
  static const swipeScreenTitle = 'TaxRefine Swipe';
  static const historyScreenTitle = 'Transaction History';
  static const tabSwipe = 'Swipe';
  static const tabHistory = 'History';

  static const loadingTransactionsFailed = 'Failed to load transactions';
  static const noPendingTransactions = 'No pending transactions';
  static const noHistory = 'No history yet';
  static const noHistorySubtitle =
      'Your processed transactions will appear here once you swipe.';
  static const businessBadge = 'Business';
  static const personalBadge = 'Personal';
  static const openReceiptFolderTooltip = 'Open receipt in Google Drive';
  static const cannotOpenReceiptLink =
      'Could not open receipt link. Please try again.';

  static const cameraOption = 'Camera';
  static const galleryOption = 'Gallery';
  static const uploadReceiptTooltip = 'Upload receipt';
  static const swipeHint = 'Swipe right for business, left for personal';

  static const personalSwipeSaved = 'Marked as personal expense';
  static String businessSwipeSaved(double deduction) {
    return 'Business swipe saved. Est. deduction: ${deduction.toStringAsFixed(2)}';
  }

  static const receiptSecuredInDrive = 'Receipt secured in your Google Drive.';
  static const receiptBackendSyncFailed =
      'Receipt uploaded, but backend sync failed';
  static const receiptUploadFailed = 'Unable to upload receipt';
  static const googleSignInCancelled = 'Google Sign-In was cancelled';
}
