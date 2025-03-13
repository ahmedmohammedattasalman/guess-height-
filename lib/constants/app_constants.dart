class AppConstants {
  // App information
  static const String appName = 'HeightGuesser';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Estimate height from images with AI';

  // Navigation routes
  static const String homeRoute = '/';
  static const String imagePreviewRoute = '/image-preview';
  static const String resultsRoute = '/results';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String historyRoute = '/history';

  // Shared preferences keys
  static const String userProfileKey = 'user_profile';
  static const String historyKey = 'history';
  static const String settingsKey = 'settings';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  static const double defaultElevation = 2.0;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Image constants
  static const double maxImageWidth = 1080.0;
  static const double maxImageHeight = 1920.0;
  static const double imageQuality = 85;

  // Reference object dimensions (in cm)
  static const Map<String, double> referenceObjectHeights = {
    'Credit Card': 8.56,
    'Standard Door': 203.2,
    'iPhone 13': 14.67,
    'Soda Can': 12.2,
    'Basketball': 24.0,
    'A4 Paper': 29.7,
  };

  // App strings
  static const String welcomeMessage = 'Welcome to HeightGuesser';
  static const String uploadImageText = 'Upload an image to estimate height';
  static const String selectReferenceObjectText =
      'Select a reference object in the image';
  static const String processingImageText = 'Processing your image...';
  static const String heightEstimationResultText = 'Estimated Height';
  static const String noHistoryText = 'No history available yet';
  static const String profileCreationText = 'Create your profile';

  // Error messages
  static const String imageUploadErrorText =
      'Failed to upload image. Please try again.';
  static const String processingErrorText =
      'Error processing the image. Please try again.';
  static const String noReferenceObjectText =
      'No reference object detected. Please try again with a clearer image.';
  static const String networkErrorText =
      'Network error. Please check your connection and try again.';
}
