import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/app_lifecycle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hfbctqmbjxsqkjjgjvcu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmYmN0cW1ianhzcWtqamdqdmN1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1ODkwODUsImV4cCI6MjA5MjE2NTA4NX0.rG-RmYrjd050Zt7POcA8Vv9QEd9Ioz_44SbXjEpatBU',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
    storageOptions: const StorageClientOptions(
      retryAttempts: 3,
    ),
  );

  runApp(const ProviderScope(child: FeezApp()));
}

class FeezApp extends ConsumerStatefulWidget {
  const FeezApp({super.key});

  @override
  ConsumerState<FeezApp> createState() => _FeezAppState();
}

class _FeezAppState extends ConsumerState<FeezApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      AppLifecycle.pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (AppLifecycle.pausedAt != null) {
        final elapsed = DateTime.now().difference(AppLifecycle.pausedAt!);
        if (elapsed > AppLifecycle.splashThreshold) {
          AppLifecycle.needsSplash = true;
          // Force le router à refaire son redirect
          appRouter.refresh();
        }
        AppLifecycle.pausedAt = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Feez',
      debugShowCheckedModeBanner: false,
      theme: feezTheme(),
      routerConfig: appRouter,
    );
  }
}
