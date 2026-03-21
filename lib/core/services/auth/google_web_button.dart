/// Platform-conditional export for the official Google Sign-In button.
/// On Web: wraps google_sign_in_web renderButton.
/// On native / test: returns SizedBox.shrink().
export 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart'
    if (dart.library.html) 'google_web_button_web.dart';

