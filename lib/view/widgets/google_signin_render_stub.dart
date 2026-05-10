import 'package:flutter/widgets.dart';

/// Web-only stub.
///
/// On non-web platforms this function is never called — the consumer
/// must gate the call on `kIsWeb`. We keep the same signature as the
/// web implementation so the conditional import resolves cleanly.
Widget renderGoogleSignInWebButton({double? minimumWidth}) {
  throw UnsupportedError(
    'renderGoogleSignInWebButton is web-only.',
  );
}
