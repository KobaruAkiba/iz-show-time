import 'package:flutter/foundation.dart';

enum MainTab { home, search, catalogue, settings }

/// Requests to switch the main tab from outside the widget tree, such as a
/// notification tap. Holds the latest request until a navigator takes it.
class MainTabRequests extends ChangeNotifier {
  MainTab? _pending;

  void show(MainTab tab) {
    _pending = tab;
    notifyListeners();
  }

  MainTab? take() {
    final tab = _pending;
    _pending = null;
    return tab;
  }
}

final MainTabRequests mainTabRequests = MainTabRequests();
