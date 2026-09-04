import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

/// A search input widget with built-in debounce functionality to reduce API calls.
///
/// Waits for the user to stop typing before executing the search.
class DebounceSearchWidget extends StatefulWidget {
  /// Called when debounced search is triggered
  final Function(String query) onSearch;
  final Duration duration;

  const DebounceSearchWidget({
    super.key,
    required this.onSearch,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<DebounceSearchWidget> createState() => _DebounceSearchWidgetState();
}

class _DebounceSearchWidgetState extends State<DebounceSearchWidget> {
  final TextEditingController _textController = TextEditingController();
  Timer? _debounceTimer;

  void _handleTextChange(String value) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(widget.duration, () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      onChanged: _handleTextChange,
      decoration: InputDecoration(
        hintText: context.l10n.searchEllipsis,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
