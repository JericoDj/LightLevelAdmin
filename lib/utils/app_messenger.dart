import 'package:flutter/material.dart';

/// Global [ScaffoldMessenger] key.
///
/// The app uses `GetMaterialApp.router` with a go_router delegate, which leaves
/// GetX's own overlay/navigator key unwired. As a result `Get.snackbar` throws
/// an "Unexpected null value" inside `_configureOverlay`. Showing messages
/// through this key avoids GetX entirely and works regardless of context.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Shows a SnackBar that does not depend on a [BuildContext] or on GetX.
void showAppSnackBar(String message, {bool isError = false}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
