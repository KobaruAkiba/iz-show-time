import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/network/dio_client.dart';
import 'core/constants/api_constants.dart';
import 'core/services/app_services.dart';
import 'core/routing/app_router.dart';
import 'presentation/navigation/main_navigator.dart';

String _resolveApiKey() {
  const tmdbKey = String.fromEnvironment('TMDB_API_KEY');
  if (tmdbKey.isNotEmpty) return tmdbKey;

  const devKey = String.fromEnvironment('DEV_TMDB_API_KEY');
  if (devKey.isNotEmpty) return devKey;

  return '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final apiKey = _resolveApiKey();
  AppApiKey.configure(apiKey);

  await DioClient.init(apiKey: apiKey);

  final appServices = AppServices();
  await appServices.initialize();
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
  @override
  void dispose() {
    widget.appServices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film/TV Tracker',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: appNavigatorKey,
      home: const MainNavigator(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
