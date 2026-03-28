/// Stub implementation for OAuth sign-in service
/// This file is loaded on non-web platforms (iOS, Android, desktop)
library oauth_sign_in_service_stub;

/// Get the user agent string - returns empty string on non-web platforms
String getUserAgent() {
  return '';
}

/// Open a new window - returns null on non-web platforms
dynamic openWindow(String url, String name, String features) {
  // Not supported on non-web platforms
  return null;
}