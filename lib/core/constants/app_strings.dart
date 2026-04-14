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
  static const tabDashboard = 'Dashboard';
  static const tabProfile = 'Profile';
  static const transactionDashboardTitle = 'Transaction Dashboard';
  static const retryAction = 'Retry';

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

  static const plaidConnectTooltip = 'Connect bank account';
  static const plaidErrorTitle = 'Plaid Link Error';
  static const plaidLinkedSuccess = 'Bank linked successfully.';
  static const plaidCancelled = 'Bank linking was cancelled.';
  static const plaidNetworkError =
      'Could not complete Plaid request. Please try again.';
  static const plaidUnexpectedError =
      'Unexpected Plaid error occurred. Please try again.';
  static const plaidMissingUserId =
      'Missing user ID. Please sign in again before linking.';
  static const plaidPreparingLink = 'Preparing Plaid Link...';
  static const plaidFinalizingLink = 'Finalizing account link...';
  static const plaidSyncingData = 'Syncing your data...';

  static const dashboardMarkedBusiness = 'Marked as BUSINESS';
  static const dashboardMarkedPersonal = 'Marked as PERSONAL';
  static const dashboardSwipeFailed =
      'Could not update transaction category. Please try again.';
  static const dashboardPullHint = 'Pull down to refresh transactions';
  static const dashboardServerUnavailable =
      'Unable to reach server. Check backend and tunnel, then pull to refresh.';
  static const dashboardRefreshBannerTitle = 'Plaid connected';
  static const dashboardRefreshBannerMessage =
      'Your transactions are syncing in the background. Pull to refresh in a few seconds.';
  static const dashboardRefreshNowAction = 'Got it';

  static const swipeSyncCompleted = 'Transactions synced. New cards are ready.';
  static const swipeSyncStillRunning =
      'Bank linked. Transactions are still syncing. Pull to refresh in a few seconds.';
}
