import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/services_wrapper/app_services.dart';
import 'presentation/navigation/main_navigator.dart';

/// Get API key from environment or dev mode
String _getApiKeyName(String prodName, String devName) {
  // For Flutter apps, check platform-specific environment
  final envVars = Platform.environment;
  final prodKey = envVars[prodName];
  if (prodKey?.isNotEmpty == true) return prodKey!;
  
  // Fall back to dev mode key
  final devKey = envVars[devName];
  return devKey ?? '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API key from environment or dev mode
  final apiKey = _getApiKeyName('TMDB_API_KEY', 'DEV_TMDB_API_KEY');
  print('🔑 Loading TMDB API key: ${apiKey.isNotEmpty ? 'Configured' : 'NOT CONFIGURED'}');
  
  // Initialize Dio client first (sets up API client)
  await DioClient.init(apiKey: apiKey);
  
  // Initialize cache and background services
  final appServices = AppServices();
  await appServices.initialize();
  await appServices.startBackgroundTasks();
  
  runApp(MyApp(appServices: appServices));
}

class MyApp extends StatefulWidget {
  final AppServices appServices;
  
  const MyApp({Key? key, required this.appServices}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Keep background tasks running in the foreground app
    widget.appServices.backgroundTaskRunner.start();
  }

  @override
  void dispose() {
    super.dispose();
    // Clean up on exit
    widget.appServices.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Film/TV Tracker',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Routing
      initialRoute: '/',
      
      // Home screen as main route
      home: const MainNavigator(),
    );
  }
}
