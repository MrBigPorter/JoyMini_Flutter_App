/// Web-specific implementation for OAuth sign-in service
/// This file is only loaded on web platforms
library oauth_sign_in_service_web;

import 'package:web/web.dart' as web_pkg;

/// Get the user agent string from the browser
String getUserAgent() {
  return web_pkg.window.navigator.userAgent;
}

/// Open a new window for OAuth authentication
dynamic openWindow(String url, String name, String features) {
  return web_pkg.window.open(url, name, features);
}