import 'package:flutter/material.dart';
import 'media_filters.dart';

/// Search text field followed by the compact filters button.
class MediaSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool filtersActive;
  final VoidCallback onFiltersPressed;

  const MediaSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.filtersActive,
    required this.onFiltersPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        MediaFiltersButton(
          isActive: filtersActive,
          onPressed: onFiltersPressed,
          compact: true,
        ),
      ],
    );
  }
}
