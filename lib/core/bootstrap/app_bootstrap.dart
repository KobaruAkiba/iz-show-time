import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/api_key_config.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../services/app_services.dart';

/// Shared Hive / network / services setup for UI and background isolates.
class AppBootstrap {
  AppBootstrap._();

  static Future<AppServices> initializeServices() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();

    final apiKey = resolveTmdbApiKey();
    AppApiKey.configure(apiKey);
    await DioClient.init(apiKey: apiKey);

    final appServices = AppServices();
    await appServices.initialize();
    return appServices;
  }
}
