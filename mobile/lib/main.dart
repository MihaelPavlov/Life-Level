import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/main_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/notifications/services/notifications_service.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase web config isn't wired; skip Firebase init in Chrome so the app
  // still boots for admin/preview work. Push notifications only run on mobile.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const ProviderScope(child: LifeLevelApp()));
}

class LifeLevelApp extends StatelessWidget {
  const LifeLevelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLevel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: navigatorKey,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      debugPrint('[AuthGate] reading token...');
      final token = await ApiClient.getToken();
      debugPrint('[AuthGate] token=${token != null ? "present" : "null"}');
      if (!mounted) return;
      setState(() {
        _home = token != null
            ? const MainShell()
            : const LoginScreen();
      });
      debugPrint('[AuthGate] navigated to ${token != null ? "MainShell" : "LoginScreen"}');
    } catch (e, st) {
      debugPrint('[AuthGate] ERROR: $e');
      debugPrint('[AuthGate] $st');
      if (!mounted) return;
      setState(() => _home = const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _home ??
        const Scaffold(
          backgroundColor: Color(0xFF040810),
          body: Center(child: CircularProgressIndicator(color: Color(0xFF4f9eff))),
        );
  }
}
