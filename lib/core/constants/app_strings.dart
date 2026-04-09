class AppStrings {
  static const appTitle = 'TaxRefine';
  static const loginSubtitle =
      'Sign in to classify transactions and securely attach receipts.';
  static const signInWithGoogle = 'Sign in with Google';
  static const signingInWithGoogle = 'Signing in...';
  static const logout = 'Logout';
  static const loginFailed = 'Sign-in failed. Please try again.';
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
  static const missingReceiptTooltip = 'Missing receipt';
  static const cannotOpenReceiptLink =
      'Could not open receipt link. Please try again.';
  static const missingReceiptMessage =
      'Missing receipt for this business transaction. You can attach one later.';

  static const takePhotoOption = 'Take Photo';
  static const uploadReceiptOption = 'Upload Receipt';
  static const uploadReceiptTooltip = 'Upload receipt';
  static const uploadingToDrive = 'Uploading to Drive...';
  static const swipeHint = 'Swipe right for business, left for personal';
  static const swipeSaveFailed = 'Could not save swipe. Please try again.';

  static const personalSwipeSaved = 'Marked as personal expense';
  static String businessSwipeSaved(double deduction) {
    return 'Business swipe saved. Est. deduction: ${deduction.toStringAsFixed(2)}';
  }

  static const receiptSecuredInDrive = 'Receipt secured in your Google Drive.';
  static const receiptBackendSyncFailed =
      'Receipt uploaded, but backend sync failed';
  static const receiptUploadFailed = 'Unable to upload receipt';
  static const googleSignInCancelled = 'Google Sign-In was cancelled';
  static const googleSignInConfigurationError =
      'Google Sign-In is not configured correctly on this build. Check google-services.json, package name, and SHA-1.';
}
