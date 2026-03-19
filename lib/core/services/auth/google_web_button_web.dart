import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart';

/// Web-only: renders the official Google Sign-In button via the GIS SDK.
/// Credential delivery is handled by authenticationEvents stream.
///
/// This widget is rendered invisibly (opacity ≈ 0) on top of our custom button.
/// [minimumWidth] is set to 400 (Google's max) so the iframe fills the click area.
Widget buildGoogleSignInWebButton() {
  return renderButton(
    configuration: GSIButtonConfiguration(
      type: GSIButtonType.standard,
      theme: GSIButtonTheme.outline,
      size: GSIButtonSize.large,
      text: GSIButtonText.signinWith,
      shape: GSIButtonShape.rectangular,
      logoAlignment: GSIButtonLogoAlignment.left,
      minimumWidth: 400,
    ),
  );
}
