import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Web implementation: defers to the official Google-rendered Sign-In
/// button, which is required on the web by `google_sign_in` 7.x. Click
/// handling is owned by Google's button — the result is delivered via
/// `GoogleSignIn.instance.authenticationEvents`.
Widget renderGoogleSignInWebButton({double? minimumWidth}) {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      theme: web.GSIButtonTheme.outline,
      size: web.GSIButtonSize.large,
      text: web.GSIButtonText.signinWith,
      shape: web.GSIButtonShape.rectangular,
      logoAlignment: web.GSIButtonLogoAlignment.left,
      minimumWidth: minimumWidth,
    ),
  );
}
