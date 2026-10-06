import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google's own button. It follows the browser's language unless a locale is
/// set, so pin it to English to match the rest of the app (it shows in the
/// tooltip and to screen readers).
Widget buildGoogleWebButton() => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        // Round, logo-only: Google's closest match to the app's sign-in orbs.
        type: web.GSIButtonType.icon,
        locale: 'en',
        theme: web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        shape: web.GSIButtonShape.pill,
      ),
    );
