import 'catalogue_item.dart';

/// A title saved to watch later, kept outside the catalogue.
class WatchlistEntry {
  const WatchlistEntry({required this.item, required this.addedAt});

  /// Always stored without tags: the watchlist has no followed/favorite state.
  final CatalogueItem item;
  final DateTime addedAt;

  String get mediaKey => item.mediaKey;

  Map<String, dynamic> toStorageJson() => {
        ...catalogueItemToStorageJson(item.copyWithTags(const [])),
        'added_at': addedAt.toIso8601String(),
      };

  /// Returns null when the type or the `added_at` date is missing or invalid.
  static WatchlistEntry? fromStorageJson(Map<String, dynamic> json) {
    final item = catalogueItemFromStorageJson(json);
    final rawDate = json['added_at'];
    if (item == null || rawDate is! String) return null;
    final addedAt = DateTime.tryParse(rawDate);
    if (addedAt == null) return null;
    return WatchlistEntry(
      item: item.copyWithTags(const []),
      addedAt: addedAt,
    );
  }
}
