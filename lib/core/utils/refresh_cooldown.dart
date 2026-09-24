/// Gates repeated refresh actions so network calls respect a minimum gap.
///
/// Call [tryBegin] before starting work; call [end] when the in-flight work
/// finishes (success or failure). While in flight, or within [duration] of the
/// last accepted begin, further [tryBegin] calls return `false`.
class RefreshCooldown {
  RefreshCooldown({required this.duration});

  final Duration duration;

  DateTime? _lastAcceptedAt;
  bool _inFlight = false;

  /// Returns `true` and marks the gate in-flight when a refresh may start.
  bool tryBegin([DateTime? now]) {
    if (_inFlight) return false;

    final at = now ?? DateTime.now();
    final last = _lastAcceptedAt;
    if (last != null && at.difference(last) < duration) {
      return false;
    }

    _lastAcceptedAt = at;
    _inFlight = true;
    return true;
  }

  /// Clears the in-flight flag so a later [tryBegin] can succeed after cooldown.
  void end() {
    _inFlight = false;
  }
}
