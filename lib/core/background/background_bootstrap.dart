import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/api_key_config.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../notifications/notification_service.dart';
import '../services/app_services.dart';

/// Initializes Hive, networking, and services for a background isolate.
class BackgroundBootstrap {
  static Future<AppServices> initializeAppServices() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();

    final apiKey = resolveTmdbApiKey();
    AppApiKey.configure(apiKey);
    await DioClient.init(apiKey: apiKey);

    final appServices = AppServices();
    await appServices.initialize();
    await NotificationService().initialize();
    return appServices;
  }
}
