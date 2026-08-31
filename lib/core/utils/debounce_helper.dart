import 'dart:async';

/// A debouncing helper to delay function execution until after a specified duration.
class DebounceHelper {
  final Map<String, Timer?> _timers = {};
  
  /// Creates and runs a new timer if one isn't currently running.
  void runWithCallback({
    required Duration duration,
    required void Function() callback,
  }) {
    // Generate key from callback
    final key = callback.toString();
    
    _cancelTimerIfActive(_timers[key]);
    _timers[key] = Timer(duration, () {
      callback();
      _timers[key] = null;
    });
  }

  /// Clears all timers.
  void clear() {
    for (var entry in _timers.entries) {
      _cancelTimerIfActive(entry.value);
    }
    _timers.clear();
  }

  static void _cancelTimerIfActive(Timer? timer) {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }
}

/// Global timers map for search debounce with explicit keys
final Map<String, Timer?> searchDebounceTimers = {};

extension SearchDebounceExtension on Function(String) {
  /// Creates a debounced version of a search function with key for tracking
  static Function(String) createDebounceable({int delayInMs = 500, String? key}) {
    if (key != null) {
      return (String query) {
        final timerToCancel = searchDebounceTimers[key];
        _cancelTimerIfActive(timerToCancel);

        searchDebounceTimers[key] = Timer(Duration(milliseconds: delayInMs), () {
          print('Searching for: "$query"');
          searchDebounceTimers[key] = null;
        });
      };
    }
    
    // Default behavior without explicit key
    return (String query) {
      final timerToCancel = searchDebounceTimers['default'];
      _cancelTimerIfActive(timerToCancel);

      searchDebounceTimers['default'] = Timer(Duration(milliseconds: delayInMs), () {
        print('Searching for: "$query"');
        searchDebounceTimers['default'] = null;
      });
    };
  }

  static void _cancelTimerIfActive(Timer? timer) {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }
}
