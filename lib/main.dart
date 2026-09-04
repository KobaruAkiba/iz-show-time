import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/network/dio_client.dart';
import 'core/constants/api_constants.dart';
import 'core/config/api_key_config.dart';
import 'core/services/app_services.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/app_lifecycle_coordinator.dart';
import 'core/background/native_background_scheduler.dart';
import 'core/routing/app_router.dart';
import 'l10n/l10n.dart';
import 'presentation/navigation/main_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final apiKey = resolveTmdbApiKey();
  AppApiKey.configure(apiKey);

  await DioClient.init(apiKey: apiKey);

  final appServices = AppServices();
  await appServices.initialize();
  await NotificationService().initialize();
  await NativeBackgroundScheduler.instance.initialize();
  await NativeBackgroundScheduler.instance.registerEpisodeChecks();
  await appServices.userDataStore.saveAppInForeground(true);
  await appServices.startBackgroundTasks();

  runApp(MyApp(appServices: appServices));
}

class MyApp extends StatefulWidget {
  final AppServices appServices;

  const MyApp({super.key, required this.appServices});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleCoordinator _lifecycleCoordinator;

  @override
  void initState() {
    super.initState();
    _lifecycleCoordinator = AppLifecycleCoordinator(
      appServices: widget.appServices,
    );
    _lifecycleCoordinator.attach();
  }

  @override
  void dispose() {
    _lifecycleCoordinator.detach();
    widget.appServices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: appNavigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        AppL10n.updateLocale(Localizations.localeOf(context));
        return child ?? const SizedBox.shrink();
      },
      home: const MainNavigator(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
