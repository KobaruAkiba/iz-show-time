import '../../data/models/catalogue_item.dart';

/// In-memory catalogue, in insertion order, with lookup by media key.
///
/// Films and TV shows share TMDB id values, so items are always identified by
/// [CatalogueItemExtension.mediaKey]. Holds state only: persistence stays
/// with the caller.
class CatalogueIndex {
  final List<CatalogueItem> _items = [];
  final Map<String, CatalogueItem> _byKey = {};

  List<CatalogueItem> get items => List.unmodifiable(_items);

  List<Film> get films => _items.whereType<Film>().toList(growable: false);

  List<TvShow> get tvShows =>
      _items.whereType<TvShow>().toList(growable: false);

  /// Only followed shows feed New Episodes and notifications.
  List<TvShow> get followedTvShows =>
      tvShows.where((show) => show.isFollowed).toList(growable: false);

  bool contains(CatalogueItem item) => _byKey.containsKey(item.mediaKey);

  /// The stored copy of [item], which carries the current tags.
  CatalogueItem? find(CatalogueItem item) => _byKey[item.mediaKey];

  TvShow? tvShowById(int id) {
    final item = _byKey[mediaKeyOf(isFilm: false, id: id)];
    return item is TvShow ? item : null;
  }

  void replaceAll(Iterable<CatalogueItem> items) {
    clear();
    items.forEach(add);
  }

  /// Adds [item], or replaces the stored copy with the same media key.
  void add(CatalogueItem item) {
    final key = item.mediaKey;
    if (_byKey.containsKey(key)) {
      final index = _items.indexWhere((entry) => entry.mediaKey == key);
      _items[index] = item;
    } else {
      _items.add(item);
    }
    _byKey[key] = item;
  }

  void remove(CatalogueItem item) {
    final key = item.mediaKey;
    _items.removeWhere((entry) => entry.mediaKey == key);
    _byKey.remove(key);
  }

  void clear() {
    _items.clear();
    _byKey.clear();
  }
}
