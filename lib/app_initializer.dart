import 'package:flutter/cupertino.dart';
import 'package:lightlevelpsychosolutionsadmin/providers/auth_listener_provider.dart';
import 'package:provider/provider.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
      Provider.of<AuthListenerProvider>(context, listen: false);

      /// ✅ Start listening WITHOUT passing context
      authProvider.startListening();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
