import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // UIScene: register BGTask launch handlers before didFinishLaunching returns.
    WorkmanagerPlugin.registerLaunchHandlers()

    // Pre-register the periodic episode-check identifier (must match Dart
    // BackgroundTaskConstants.episodeCheckUniqueName + Info.plist).
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.izshowtime.tracker.episode_check",
      earliestBeginInSeconds: NSNumber(value: 2 * 60 * 60)
    )

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
