import 'package:flutter/widgets.dart';

import '../services/app_services.dart';

/// Tracks whether the app is open in the foreground and reloads alerts on resume.
class AppLifecycleCoordinator with WidgetsBindingObserver {
  AppLifecycleCoordinator({required AppServices appServices})
      : _appServices = appServices;

  final AppServices _appServices;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    _persistForegroundState(_isOpenState(AppLifecycleState.resumed));
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _persistForegroundState(_isOpenState(state));

    if (state == AppLifecycleState.resumed) {
      _appServices.reloadNewEpisodeAlertsFromStore();
    }
  }

  bool _isOpenState(AppLifecycleState state) {
    return state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  void _persistForegroundState(bool isOpen) {
    Future<void>(() async {
      await _appServices.userDataStore.saveAppInForeground(isOpen);
      await _appServices.userDataStore.flush();
    });
  }
}
