# Watchlist Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aggiungere una watchlist ("To watch") come stato alternativo al catalogo: bottone nel dettaglio, vista dedicata nella tab Catalogo, serie dal segnalibro di Cerca in watchlist, migrazione una tantum delle serie bookmark-only.

**Architecture:** Entità separata (`WatchlistEntry`) persistita in una nuova box Hive `watchlist`, tenuta in memoria da `WatchlistIndex` e gestita da `WatchlistService` (iniettato in `AppServices` come `EpisodeAlertsService`). L'unico aggancio con il catalogo è in `addToCatalogue` (watchlist → catalogo); la UI legge `libraryStatusOf` prima delle azioni per scegliere i messaggi. `CatalogueScreen` diventa una shell con `SegmentedButton` che alterna `CatalogueView` (corpo attuale, invariato) e `WatchlistView`.

**Tech Stack:** Flutter / Dart 3 (sealed/records ammessi), hive_ce, `ValueNotifier`/`ValueListenableBuilder`, `setState`, flutter_test con fake scritti a mano, intl/ARB (`flutter gen-l10n`).

**Spec:** docs/superpowers/specs/2026-11-17-watchlist-design.md

## Global Constraints

- `StorageConstants.storageSchemaVersion` resta `3`: nessun bump, nessuna migrazione di schema.
- `HiveUserDataStore._backupVersion` resta `2`; la sezione `'watchlist'` del backup è opzionale (assente → watchlist vuota).
- `'watchlist_migration_v1_done'` **non** entra in `_backupMetaKeys` (così l'import azzera il flag e la migrazione si riesegue).
- L'istanza `_readOnly` di `HiveUserDataStore` (isolate in background) non apre mai la box `watchlist`; `UserDataSnapshot` non cambia.
- Nessuna nuova dipendenza in `pubspec.yaml`; nessuna nuova libreria di state management (singleton `AppServices`, `ValueNotifier`, `setState`).
- `addToCatalogue` è l'unico punto in cui un titolo lascia la watchlist per entrare nel catalogo; `removeFromCatalogue` non rimette mai nulla in watchlist.
- Invariante permanente: in catalogo solo serie con ≥ 1 episodio visto; le serie aggiunte dal segnalibro vanno in watchlist.
- La watchlist non tocca statistiche, conteggi del catalogo, `followedTvShows`, avvisi nuovi episodi, sync TMDB: `WatchlistService` non dipende da `TmdbService`.
- Le voci si identificano per `mediaKey` (`m_<id>` film, `t_<id>` serie).
- Stringhe solo in `lib/l10n/app_en.arb`, con chiavi e testi esatti della tabella dello spec §6.3; dopo ogni modifica `flutter gen-l10n` e commit dei file generati (`lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart` sono tracciati).
- Test: fake scritti a mano, nessun mock/mocktail; il fake condiviso è `test/support/fake_user_data_store.dart`.
- `flutter analyze` deve restare a `No issues found!` (baseline verificata).
- Comportamento del catalogo invariato; l'unica modifica a `media_filters.dart` è la rinomina del parametro in `recencyByMediaKey`; `showMediaFiltersSheet` non si modifica.
- Icone watchlist: `Icons.playlist_add` / `Icons.playlist_add_check`; target ≥ 48 dp; stato mai affidato al solo colore.
- Snackbar con Undo: `duration: const Duration(seconds: 6)`.
- Async: `mounted` check dopo ogni `await` prima di usare `context`; catturare `ScaffoldMessenger.of(context)` prima dell'`await` quando serve dopo.
- Commit: frase breve all'imperativo, senza prefissi; ogni commit termina con riga vuota + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (secondo `-m`).

## Review Focus

1. **Film e serie con lo stesso id TMDB**: l'ingresso in catalogo della serie `t_7` non toglie dalla watchlist il film `m_7`, e viceversa → test in Task 5.
2. **Undo dopo che il titolo è entrato nel catalogo**: `restore` viene ignorato, la watchlist e lo store restano senza la voce → test in Task 4.
3. **Backup con sezione `watchlist` corrotta** (non-mappa, voce senza `added_at`, chiave non scrivibile): import rifiutato o annullato, catalogo e watchlist correnti intatti → test in Task 2.
4. **Doppio tap su "aggiungi"** (`Future.wait` di due `add`): una sola voce, una sola scrittura, risultati `{added, alreadyPresent}` → test in Task 4.
5. **Film in catalogo senza `WatchRecord`** (runtime TMDB assente): nel dettaglio il bottone è `inCatalogue` (disabilitato), non `available` → test in Task 10.

---

## File Structure

| File | Azione | Responsabilità |
|---|---|---|
| `lib/data/models/watchlist_entry.dart` | Create | Modello `WatchlistEntry` + (de)serializzazione storage |
| `lib/data/repositories/watchlist_store.dart` | Create | Interfaccia `WatchlistStore` (3 metodi dello spec) |
| `lib/data/repositories/user_data_store.dart` | Modify | `implements WatchlistStore` + flag migrazione |
| `lib/data/repositories/hive_user_data_store.dart` | Modify | Box `watchlist`, flag, backup, clear/flush/close |
| `lib/core/constants/storage_constants.dart` | Modify | `watchlistBoxName`, `watchlistMigrationV1DoneKey` |
| `lib/core/services/watchlist_index.dart` | Create | Stato in memoria, nessun I/O |
| `lib/core/services/watchlist_service.dart` | Create | Regole watchlist + persistenza + `listenable` |
| `lib/core/services/library_status.dart` | Create | `enum LibraryStatus`, `enum LibraryToggleResult` |
| `lib/core/services/bookmark_only_shows_migration.dart` | Create | Migrazione una tantum serie a 0 episodi |
| `lib/core/services/app_services.dart` | Modify | Campo `watchlist`, aggancio, `libraryStatusOf`, toggle, init/clear |
| `lib/presentation/widgets/media_filters.dart` | Modify | Solo rinomina parametro `recencyByMediaKey` |
| `lib/presentation/widgets/media_search_field.dart` | Create | Campo ricerca + `MediaFiltersButton` |
| `lib/presentation/widgets/active_media_filter_chips.dart` | Create | Chip tipo + ordinamento + `extraChips` |
| `lib/presentation/widgets/media_card.dart` | Modify | Parametro opzionale `trailingAction` (additivo) |
| `lib/presentation/widgets/watchlist_snack_bars.dart` | Create | Snackbar watchlist (Undo 6 s) |
| `lib/presentation/widgets/watchlist_button.dart` | Create | `WatchlistButton` a tre stati + mapping |
| `lib/presentation/widgets/media_detail_sheet.dart` | Modify | Bottone watchlist + messaggio "Moved..." |
| `lib/presentation/screens/catalogue/catalogue_screen.dart` | Modify | Shell: header, switch, corpo del segmento |
| `lib/presentation/screens/catalogue/catalogue_view.dart` | Create | Corpo attuale del catalogo, invariato |
| `lib/presentation/screens/catalogue/library_segment_switch.dart` | Create | `SegmentedButton<LibrarySegment>` con semantics |
| `lib/presentation/screens/catalogue/watchlist_view.dart` | Create | Vista watchlist |
| `lib/presentation/screens/catalogue/watchlist_counts_row.dart` | Create | Riga conteggi che funge da filtro tipo |
| `lib/presentation/screens/search/library_toggle_message.dart` | Create | Testo snackbar da `LibraryToggleResult` |
| `lib/presentation/screens/search/search_screen.dart` | Modify | `_toggleItem` + rinomina parametro |
| `lib/presentation/navigation/main_navigator.dart` | Modify | Callback verso tab Cerca |
| `lib/l10n/app_en.arb` (+ generati) | Modify | Le 17 chiavi dello spec, aggiunte dal task che le usa |
| `test/support/fake_user_data_store.dart` | Create | `FakeUserDataStore` estratto e condiviso |
| `test/services/app_services_persistence_test.dart` | Modify | Usa il fake condiviso; nuovo gruppo watchlist |
| `test/notifications/new_episode_checker_test.dart` | Modify | `FakeEpisodeCheckStore` implementa i nuovi metodi |
| `test/core/catalogue_activity_test.dart` | Modify | Rinomina parametro |
| test nuovi | Create | `watchlist_entry_test`, `watchlist_index_test`, `watchlist_service_test`, `bookmark_only_shows_migration_test`, `catalogue_screen_test`, `watchlist_view_test`, `watchlist_button_test`, `library_toggle_message_test` |

Scelte del builder (spec §9): `libraryStatusOf` è metodo di `AppServices`; le viste stanno in `screens/catalogue/`; `UserDataStore implements WatchlistStore`.

---

### Task 1: WatchlistEntry, WatchlistStore e box Hive

**Files:**
- Create: `lib/data/models/watchlist_entry.dart`, `lib/data/repositories/watchlist_store.dart`, `test/support/fake_user_data_store.dart`, `test/models/watchlist_entry_test.dart`
- Modify: `lib/core/constants/storage_constants.dart:2-4`, `lib/data/repositories/user_data_store.dart:6-80`, `lib/data/repositories/hive_user_data_store.dart:60-77,577-607,668-676`, `test/services/app_services_persistence_test.dart:15-232` (classe spostata nel file support + import), `test/notifications/new_episode_checker_test.dart:13`
- Test: `test/models/watchlist_entry_test.dart`, `test/repositories/hive_user_data_store_test.dart`

**Interfaces:**
- Consumes: `catalogueItemToStorageJson`, `catalogueItemFromStorageJson`, `CatalogueItem.copyWithTags`, `mediaKey` (esistenti).
- Produces:
  - `class WatchlistEntry { const WatchlistEntry({required CatalogueItem item, required DateTime addedAt}); final CatalogueItem item; final DateTime addedAt; String get mediaKey; Map<String, dynamic> toStorageJson(); static WatchlistEntry? fromStorageJson(Map<String, dynamic> json); }`
  - `abstract interface class WatchlistStore { Future<List<WatchlistEntry>> loadWatchlist(); Future<void> saveWatchlistEntry(WatchlistEntry e); Future<void> removeWatchlistEntry(String mediaKey); }`
  - `abstract class UserDataStore implements WatchlistStore` con in più `Future<bool> loadWatchlistMigrationDone();` e `Future<void> saveWatchlistMigrationDone();`
  - `StorageConstants.watchlistBoxName = 'watchlist'`, `StorageConstants.watchlistMigrationV1DoneKey = 'watchlist_migration_v1_done'`
  - `HiveUserDataStore.watchlistBox` (getter `Box<dynamic>`)
  - `FakeUserDataStore` (in `test/support/fake_user_data_store.dart`) con `final List<WatchlistEntry> watchlist` e `bool watchlistMigrationDone`

- [ ] **Step 1: Write the failing tests**

```dart
// test/models/watchlist_entry_test.dart
test('storage json round-trip drops tags and overview, keeps addedAt', () {
  final entry = WatchlistEntry(
    item: const TvShow(id: 7, title: 'Show', overview: 'Long', tags: [kFollowedTag, kFavoriteTag]),
    addedAt: DateTime(2026, 11, 17, 9, 30),
  );
  final json = entry.toStorageJson();
  expect(json['added_at'], '2026-11-17T09:30:00.000');
  final restored = WatchlistEntry.fromStorageJson(json);
  expect(restored?.item, isA<TvShow>());
  expect(restored?.mediaKey, 't_7');
  expect(restored?.item.tags, isEmpty);
  expect(restored?.item.overview, isNull);
  expect(restored?.addedAt, DateTime(2026, 11, 17, 9, 30));
});

test('fromStorageJson returns null without a valid date or type', () {
  expect(WatchlistEntry.fromStorageJson({'type': 'tv', 'id': 1, 'title': 'No date'}), isNull);
  expect(WatchlistEntry.fromStorageJson({'type': 'tv', 'id': 1, 'title': 'Bad', 'added_at': 'x'}), isNull);
  expect(WatchlistEntry.fromStorageJson({'type': 'person', 'id': 1, 'added_at': '2026-01-01T00:00:00.000'}), isNull);
});
```

```dart
// test/repositories/hive_user_data_store_test.dart, dentro group('HiveUserDataStore')
test('round-trips watchlist entries and clearAll removes them', () async {
  final film = WatchlistEntry(item: const Film(id: 7, title: 'Film'), addedAt: DateTime(2026, 1, 1));
  final show = WatchlistEntry(item: const TvShow(id: 7, title: 'Show'), addedAt: DateTime(2026, 2, 1));
  await store.saveWatchlistEntry(film);
  await store.saveWatchlistEntry(show);
  expect(store.watchlistBox.keys.toSet(), {'m_7', 't_7'});
  expect(store.watchlistBox.get('t_7'), isA<String>());

  await store.removeWatchlistEntry('m_7');
  expect((await store.loadWatchlist()).single.addedAt, DateTime(2026, 2, 1));

  await store.clearAll();
  expect(await store.loadWatchlist(), isEmpty);
});

test('persists the watchlist migration flag', () async {
  expect(await store.loadWatchlistMigrationDone(), isFalse);
  await store.saveWatchlistMigrationDone();
  expect(await store.loadWatchlistMigrationDone(), isTrue);
  expect(store.metaBox.get(StorageConstants.watchlistMigrationV1DoneKey), isTrue);
});

test('readSnapshot never opens the watchlist box', () async {
  await store.close();
  await Hive.deleteBoxFromDisk(StorageConstants.watchlistBoxName);

  await HiveUserDataStore.readSnapshot();

  expect(File('${tempDir.path}/watchlist.hive').existsSync(), isFalse);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/watchlist_entry_test.dart test/repositories/hive_user_data_store_test.dart`
Expected: FAIL — compilazione: `WatchlistEntry` / `saveWatchlistEntry` / `watchlistBox` non definiti.

- [ ] **Step 3: Implement**
  - `WatchlistEntry` in `lib/data/models/watchlist_entry.dart`: `toStorageJson()` = `{...catalogueItemToStorageJson(item.copyWithTags(const [])), 'added_at': addedAt.toIso8601String()}`; `fromStorageJson` restituisce `null` se `catalogueItemFromStorageJson` dà `null` o `added_at` non è una `String` parsabile con `DateTime.tryParse`; l'`item` restituito ha `tags` vuoti.
  - `WatchlistStore` in `lib/data/repositories/watchlist_store.dart` (firma esatta dello spec §6.1).
  - `UserDataStore implements WatchlistStore` + i due metodi del flag (dartdoc: "Missing means false").
  - `StorageConstants`: le due costanti sopra.
  - `HiveUserDataStore`: `open()` apre `watchlist` solo se `!_readOnly` (`_watchlistBox ??= await _openBox(...)`); `loadWatchlist` salta le voci corrotte con `debugPrint` come `loadCatalogue`; `saveWatchlistEntry` usa `_putEncodedMap(watchlistBox, e.mediaKey, e.toStorageJson())`; `removeWatchlistEntry` → `delete`; flag: `metaBox.get(key) == true` / `put(key, true)`; `flush` include la box watchlist quando aperta; `clearAll` fa `watchlistBox.clear()` (il flag resta); `close` chiude e azzera `_watchlistBox`.
  - Sposta `FakeUserDataStore` da `test/services/app_services_persistence_test.dart:15-232` a `test/support/fake_user_data_store.dart` (import relativo `../support/fake_user_data_store.dart` nel test) e aggiungi: `watchlist` (save sostituisce per `mediaKey`), `watchlistMigrationDone`, `clearAll` svuota `watchlist`.
  - `FakeEpisodeCheckStore` (`test/notifications/new_episode_checker_test.dart:13`): stub vuoti dei 5 nuovi metodi (`loadWatchlist` → `[]`, flag → `false`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/models/watchlist_entry_test.dart test/repositories test/services test/notifications`
Expected: PASS (tutti, inclusi i test esistenti che usano i due fake).

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/watchlist_entry.dart lib/data/repositories/watchlist_store.dart lib/data/repositories/user_data_store.dart lib/data/repositories/hive_user_data_store.dart lib/core/constants/storage_constants.dart test/support/fake_user_data_store.dart test/models/watchlist_entry_test.dart test/repositories/hive_user_data_store_test.dart test/services/app_services_persistence_test.dart test/notifications/new_episode_checker_test.dart
git commit -m "Store watchlist entries in their own Hive box" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Watchlist nel backup

**Files:**
- Modify: `lib/data/repositories/hive_user_data_store.dart:109-211`, `test/support/fake_user_data_store.dart` (export/import)
- Test: `test/repositories/hive_user_data_store_test.dart`

**Interfaces:**
- Consumes: `WatchlistEntry.fromStorageJson`, `watchlistBox`, `StorageConstants.watchlistMigrationV1DoneKey` (Task 1).
- Produces: backup con chiave opzionale `'watchlist'` (mappa `mediaKey` → JSON-string), `version` sempre `2`. `FakeUserDataStore.exportBackupData` include `'watchlist'` (lista di `toStorageJson()`); `importBackupData` la ripristina (assente → vuota) e rimette `watchlistMigrationDone = false`.

- [ ] **Step 1: Write the failing tests**

```dart
WatchlistEntry entry(int id, String title) =>
    WatchlistEntry(item: TvShow(id: id, title: title), addedAt: DateTime(2026, 3, 1, 8));
Map<String, dynamic> backupWith({Map<String, dynamic> catalogue = const {}, Object? watchlist}) => {
      'format': 'iz_show_time_backup', 'version': 2, 'catalogue': catalogue,
      'watchHistory': <String, dynamic>{}, 'meta': <String, dynamic>{},
      if (watchlist != null) 'watchlist': watchlist,
    };

test('backup round-trips the watchlist and keeps version 2', () async {
  await store.saveWatchlistEntry(entry(7, 'Saved Show'));
  final backup = await store.exportBackupData();
  expect(backup['version'], 2);
  expect((backup['watchlist'] as Map).keys, ['t_7']);

  await store.clearAll();
  await store.importBackupData(backup);

  final loaded = await store.loadWatchlist();
  expect(loaded.single.item.title, 'Saved Show');
  expect(loaded.single.addedAt, DateTime(2026, 3, 1, 8));
});

test('a backup without a watchlist section imports an empty watchlist', () async {
  await store.saveWatchlistEntry(entry(7, 'Old'));
  await store.importBackupData(backupWith());
  expect(await store.loadWatchlist(), isEmpty);
});

test('import resets the watchlist migration flag', () async {
  await store.saveWatchlistMigrationDone();
  final backup = await store.exportBackupData();
  expect((backup['meta'] as Map).containsKey(StorageConstants.watchlistMigrationV1DoneKey), isFalse);
  await store.importBackupData(backup);
  expect(await store.loadWatchlistMigrationDone(), isFalse);
});

// Review Focus 3
test('rejects an invalid watchlist section and keeps current data', () async {
  await store.saveCatalogueItem(const Film(id: 5, title: 'Kept Film'));
  await store.saveWatchlistEntry(entry(7, 'Kept Show'));
  await expectLater(store.importBackupData(backupWith(watchlist: ['not a map'])), throwsFormatException);
  await expectLater(
    store.importBackupData(backupWith(watchlist: {'t_1': jsonEncode({'type': 'tv', 'id': 1, 'title': 'No date'})})),
    throwsFormatException,
  );

  expect((await store.loadCatalogue()).single.title, 'Kept Film');
  expect((await store.loadWatchlist()).single.item.title, 'Kept Show');
});

test('a failing watchlist write rolls the whole import back', () async {
  await store.saveCatalogueItem(const Film(id: 5, title: 'Kept Film'));
  await store.saveWatchlistEntry(entry(7, 'Kept Show'));

  await expectLater(
    store.importBackupData(backupWith(
      catalogue: {'m_9': jsonEncode({'type': 'film', 'id': 9, 'title': 'Imported'})},
      // Hive rejects String keys longer than 255 characters.
      watchlist: {'k' * 256: jsonEncode(entry(8, 'Bad key').toStorageJson())},
    )),
    throwsA(isA<HiveError>()),
  );

  expect((await store.loadCatalogue()).single.title, 'Kept Film');
  expect((await store.loadWatchlist()).single.item.title, 'Kept Show');
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/repositories/hive_user_data_store_test.dart`
Expected: FAIL — `backup['watchlist']` è `null`; gli import con sezione invalida non lanciano.

- [ ] **Step 3: Implement backup in `HiveUserDataStore`**
  - `exportBackupData`: aggiunge `'watchlist': _stringifyMapEntries(watchlistBox.toMap())`.
  - `importBackupData`: `watchlist` = `data.containsKey('watchlist') ? _decodeBackupSection(data['watchlist']) : <dynamic, dynamic>{}`; `_validateBackupEntries` riceve anche la watchlist e lancia `FormatException('Invalid watchlist entry')` se `fromStorageJson` dà `null`; `previous` include `watchlist`.
  - `_replaceBoxContents({..., required Map<dynamic, dynamic> watchlist})`: la box watchlist si svuota e si scrive **per ultima** (dopo catalogo, storia e meta), sia nell'import sia nel rollback.
  - `_backupMetaKeys` invariato.
  - Fake: export/import come da Interfaces.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/repositories test/services`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/hive_user_data_store.dart test/repositories/hive_user_data_store_test.dart test/support/fake_user_data_store.dart
git commit -m "Include the watchlist in backups without bumping their version" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: WatchlistIndex

**Files:**
- Create: `lib/core/services/watchlist_index.dart`
- Test: `test/services/watchlist_index_test.dart`

**Interfaces:**
- Consumes: `WatchlistEntry` (Task 1).
- Produces:

```dart
class WatchlistIndex {
  List<WatchlistEntry> get entries;          // unmodifiable, insertion order
  List<CatalogueItem> get items;
  bool contains(CatalogueItem item);
  WatchlistEntry? find(CatalogueItem item);
  Map<String, DateTime> get addedAtByMediaKey;
  void add(WatchlistEntry entry);            // replaces the entry with the same mediaKey
  void remove(CatalogueItem item);
  void replaceAll(Iterable<WatchlistEntry> entries);
  void clear();
}
```

- [ ] **Step 1: Write the failing test**

```dart
final film = WatchlistEntry(item: const Film(id: 7, title: 'Film'), addedAt: DateTime(2026, 1, 1));
final show = WatchlistEntry(item: const TvShow(id: 7, title: 'Show'), addedAt: DateTime(2026, 2, 1));

test('film and show with the same id are distinct', () {
  final index = WatchlistIndex()..add(film);
  expect(index.contains(const Film(id: 7, title: 'x')), isTrue);
  expect(index.contains(const TvShow(id: 7, title: 'x')), isFalse);
  index.add(show);
  expect(index.addedAtByMediaKey, {'m_7': DateTime(2026, 1, 1), 't_7': DateTime(2026, 2, 1)});
});

test('add replaces, remove and replaceAll update every view', () {
  final index = WatchlistIndex()..add(film);
  index.add(WatchlistEntry(item: film.item, addedAt: DateTime(2026, 5, 1)));
  expect(index.entries, hasLength(1));
  expect(index.find(film.item)?.addedAt, DateTime(2026, 5, 1));
  index.remove(film.item);
  expect(index.items, isEmpty);
  index.replaceAll([film, show]);
  expect(index.items.map((item) => item.mediaKey), ['m_7', 't_7']);
  expect(() => index.entries.add(film), throwsUnsupportedError);
  index.clear();
  expect(index.addedAtByMediaKey, isEmpty);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/watchlist_index_test.dart`
Expected: FAIL — `WatchlistIndex` non definito.

- [ ] **Step 3: Implement `WatchlistIndex` in `lib/core/services/watchlist_index.dart`** — stessa struttura di `CatalogueIndex` (lista + mappa per `mediaKey`), nessun I/O.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/watchlist_index_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/watchlist_index.dart test/services/watchlist_index_test.dart
git commit -m "Add in-memory watchlist index" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: WatchlistService

**Files:**
- Create: `lib/core/services/watchlist_service.dart`
- Test: `test/services/watchlist_service_test.dart`

**Interfaces:**
- Consumes: `WatchlistIndex` (Task 3), `WatchlistStore`, `WatchlistEntry` (Task 1), `catalogueItemForLocalStore` (esistente).
- Produces:

```dart
enum WatchlistAddResult { added, alreadyPresent, alreadyInCatalogue }

class WatchlistService {
  WatchlistService({
    required WatchlistStore Function() store,
    required Future<void> Function() flushIfIdle,
    required bool Function(CatalogueItem) isInCatalogue,
    DateTime Function() clock = DateTime.now,
  });
  ValueListenable<List<WatchlistEntry>> get listenable;
  List<WatchlistEntry> get entries;
  Map<String, DateTime> get addedAtByMediaKey;
  bool contains(CatalogueItem item);
  WatchlistEntry? entryFor(CatalogueItem item);
  Future<WatchlistAddResult> add(CatalogueItem item);
  Future<bool> remove(CatalogueItem item);
  Future<void> restore(WatchlistEntry entry);
  Future<void> loadFrom(WatchlistStore store);
  void clear();
}
```

- [ ] **Step 1: Write the failing test**

```dart
class _FakeWatchlistStore implements WatchlistStore {
  final Map<String, WatchlistEntry> entries = {};
  int saveCount = 0;
  final List<String> removed = [];
  @override
  Future<List<WatchlistEntry>> loadWatchlist() async => entries.values.toList();
  @override
  Future<void> saveWatchlistEntry(WatchlistEntry e) async { saveCount++; entries[e.mediaKey] = e; }
  @override
  Future<void> removeWatchlistEntry(String mediaKey) async { removed.add(mediaKey); entries.remove(mediaKey); }
}

late _FakeWatchlistStore store;
late Set<String> catalogued;
late int flushCount;
late WatchlistService service;
const show = TvShow(id: 7, title: 'Show', tags: [kFollowedTag]);
final now = DateTime(2026, 11, 17, 9);

setUp(() {
  store = _FakeWatchlistStore();
  catalogued = {};
  flushCount = 0;
  service = WatchlistService(
    store: () => store,
    flushIfIdle: () async => flushCount++,
    isInCatalogue: (item) => catalogued.contains(item.mediaKey),
    clock: () => now,
  );
});

test('add stores a tagless entry, persists it and flushes', () async {
  expect(await service.add(show), WatchlistAddResult.added);
  expect(service.entries.single.addedAt, now);
  expect(service.entries.single.item.tags, isEmpty);
  expect(store.entries.keys, ['t_7']);
  expect(flushCount, 1);
  expect(service.listenable.value, hasLength(1));
});

test('add refuses a catalogued title', () async {
  catalogued.add('t_7');
  expect(await service.add(show), WatchlistAddResult.alreadyInCatalogue);
  expect(service.entries, isEmpty);
  expect(store.saveCount, 0);
});

// Review Focus 4
test('a double tap adds the title only once', () async {
  final results = await Future.wait([service.add(show), service.add(show)]);
  expect(results.toSet(), {WatchlistAddResult.added, WatchlistAddResult.alreadyPresent});
  expect(store.saveCount, 1);
});

test('remove reports whether the entry existed', () async {
  await service.add(show);
  expect(await service.remove(show), isTrue);
  expect(await service.remove(show), isFalse);
  expect(store.removed, ['t_7']);
});

test('restore keeps the original addedAt', () async {
  await service.add(show);
  final entry = service.entryFor(show);
  await service.remove(show);
  await service.restore(entry!); // test-only: entry was just added
  expect(service.addedAtByMediaKey['t_7'], now);
  expect(store.entries.containsKey('t_7'), isTrue);
});

// Review Focus 2
test('restore is ignored once the title is in the catalogue', () async {
  catalogued.add('t_7');
  await service.restore(WatchlistEntry(item: show, addedAt: now));
  expect(service.contains(show), isFalse);
  expect(store.saveCount, 0);
});

test('loadFrom drops entries already in the catalogue', () async {
  store.entries['t_7'] = WatchlistEntry(item: show, addedAt: now);
  store.entries['m_8'] = WatchlistEntry(item: const Film(id: 8, title: 'Film'), addedAt: now);
  catalogued.add('t_7');
  await service.loadFrom(store);
  expect(service.entries.map((e) => e.mediaKey), ['m_8']);
  expect(store.removed, ['t_7']);
});

test('clear empties memory and notifies, leaving the store alone', () async {
  await service.add(show);
  service.clear();
  expect(service.listenable.value, isEmpty);
  expect(store.entries, hasLength(1));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/watchlist_service_test.dart`
Expected: FAIL — `WatchlistService` non definito.

- [ ] **Step 3: Implement `WatchlistService` in `lib/core/services/watchlist_service.dart`** — controlli (`isInCatalogue`, `contains`) e mutazione dell'indice **prima** di qualunque `await` (è ciò che rende sicuro il doppio tap); l'item in memoria è `catalogueItemForLocalStore(item).copyWithTags(const [])`; ogni mutazione pubblica una copia della lista sul `ValueNotifier`; le scritture sullo store sono in `try/catch` con `debugPrint` (stesso stile di `_persistCatalogueItem`) seguite da `flushIfIdle()`; `loadFrom` rimuove dallo store le voci scartate.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/watchlist_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/watchlist_service.dart test/services/watchlist_service_test.dart
git commit -m "Add watchlist service with add, remove and undo rules" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Integrazione in AppServices

**Files:**
- Create: `lib/core/services/library_status.dart`
- Modify: `lib/core/services/app_services.dart:59-67` (campo), `:108` (vicino a `isInCatalogue`: `libraryStatusOf`), `:115-128` (aggancio), `:280-292` (toggle), `:547-556` (initialize), `:752-756` (clearAllData)
- Test: `test/services/app_services_persistence_test.dart` (nuovo `group('AppServices watchlist')`)

**Interfaces:**
- Consumes: `WatchlistService`, `WatchlistAddResult` (Task 4); `FakeUserDataStore.watchlist` (Task 1-2).
- Produces:
  - `enum LibraryStatus { none, watchlist, catalogue }` e `enum LibraryToggleResult { addedToCatalogue, removedFromCatalogue, addedToWatchlist, alreadyOnWatchlist }` in `lib/core/services/library_status.dart`
  - `late final WatchlistService watchlist` (pubblico) in `AppServices`
  - `LibraryStatus libraryStatusOf(CatalogueItem item)` (catalogo ha precedenza sulla watchlist)
  - `Future<LibraryToggleResult> toggleCatalogueItem(CatalogueItem item)` (prima `Future<void>`)

- [ ] **Step 1: Write the failing tests**

```dart
group('AppServices watchlist', () {
  late AppServices appServices;
  late FakeUserDataStore store;
  const film = Film(id: 70, title: 'Watchlist Film');
  const show = TvShow(id: 71, title: 'Watchlist Show');
  final episode = EpisodeModel.fromJson({
    'id': 7101, 'season_number': 1, 'episode_number': 1,
    'name': 'Pilot', 'air_date': '2020-01-01', 'runtime': 30,
  });

  setUp(() async {
    appServices = AppServices();
    store = FakeUserDataStore();
    appServices.userDataStore = store;
    appServices.tmdbService = StubTmdbService(seasonCount: 1, episodesBySeason: {1: [episode]});
    await appServices.clearAllData();
  });

  Future<void> expectEntryPathLeavesWatchlist(CatalogueItem item, Future<void> Function() enter) async {
    await appServices.watchlist.add(item);
    await enter();
    expect(appServices.isInCatalogue(item), isTrue);
    expect(appServices.watchlist.contains(item), isFalse);
    expect(store.watchlist, isEmpty);
  }

  test('addToCatalogue takes the title off the watchlist', () =>
      expectEntryPathLeavesWatchlist(film, () => appServices.addToCatalogue(film)));
  test('addToCatalogueWithWatchTime takes the film off the watchlist', () =>
      expectEntryPathLeavesWatchlist(film, () => appServices.addToCatalogueWithWatchTime(film)));
  test('toggleCatalogueItem on a film takes it off the watchlist', () =>
      expectEntryPathLeavesWatchlist(film, () => appServices.toggleCatalogueItem(film)));
  test('markFilmWatched takes the film off the watchlist', () =>
      expectEntryPathLeavesWatchlist(film, () => appServices.markFilmWatched(film: film, durationMinutes: 100)));
  test('markEpisodeWatched takes the show off the watchlist', () =>
      expectEntryPathLeavesWatchlist(show, () => appServices.markEpisodeWatched(show: show, episode: episode)));
  test('addSeasonToCatalogue takes the show off the watchlist', () =>
      expectEntryPathLeavesWatchlist(show, () => appServices.addSeasonToCatalogue(show: show, episodes: [episode])));

  // Review Focus 1
  test('cataloguing a show keeps the film with the same id on the watchlist', () async {
    const sameIdFilm = Film(id: 71, title: 'Same Id Film');
    await appServices.watchlist.add(sameIdFilm);
    await appServices.markEpisodeWatched(show: show, episode: episode);
    expect(appServices.watchlist.contains(sameIdFilm), isTrue);
  });

  test('the bookmark sends a show to the watchlist, never to the catalogue', () async {
    expect(await appServices.toggleCatalogueItem(show), LibraryToggleResult.addedToWatchlist);
    expect(await appServices.toggleCatalogueItem(show), LibraryToggleResult.alreadyOnWatchlist);
    expect(appServices.isInCatalogue(show), isFalse);
    expect(appServices.tvShows.where((s) => appServices.watchedEpisodesCountFor(s.id) == 0), isEmpty);
  });

  test('the bookmark adds a film and removes a catalogued title', () async {
    expect(await appServices.toggleCatalogueItem(film), LibraryToggleResult.addedToCatalogue);
    expect(await appServices.toggleCatalogueItem(film), LibraryToggleResult.removedFromCatalogue);
    expect(appServices.watchlist.contains(film), isFalse);
  });

  test('libraryStatusOf reports none, watchlist and catalogue', () async {
    expect(appServices.libraryStatusOf(film), LibraryStatus.none);
    await appServices.watchlist.add(film);
    expect(appServices.libraryStatusOf(film), LibraryStatus.watchlist);
    await appServices.addToCatalogue(film);
    expect(appServices.libraryStatusOf(film), LibraryStatus.catalogue);
  });

  test('the watchlist stays out of stats and followed shows', () async {
    await appServices.watchlist.add(film);
    await appServices.watchlist.add(show);
    expect(appServices.catalogue, isEmpty);
    expect(appServices.followedTvShows, isEmpty);
    expect(appServices.totalWatchTimeMinutes, 0);
    expect(appServices.filmsWatchedCount, 0);
  });

  test('initialize drops watchlist entries already in the catalogue', () async {
    store.catalogue.add(film);
    store.watchlist.addAll([
      WatchlistEntry(item: film, addedAt: DateTime(2026, 1, 1)),
      WatchlistEntry(item: const Film(id: 72, title: 'Other'), addedAt: DateTime(2026, 1, 2)),
    ]);
    await appServices.initialize(userDataStore: store);
    expect(appServices.watchlist.entries.map((e) => e.mediaKey), ['m_72']);
    expect(store.watchlist.map((e) => e.mediaKey), ['m_72']);
  });

  test('clearAllData empties the watchlist', () async {
    await appServices.watchlist.add(film);
    await appServices.clearAllData();
    expect(appServices.watchlist.entries, isEmpty);
    expect(store.watchlist, isEmpty);
  });

  test('backup round-trip keeps watchlist entries and dates', () async {
    await appServices.watchlist.restore(WatchlistEntry(item: film, addedAt: DateTime(2026, 4, 1)));
    final backup = await appServices.exportUserDataBackup();
    await appServices.clearAllData();
    await appServices.restoreUserDataBackup(backup);
    expect(appServices.watchlist.addedAtByMediaKey, {'m_70': DateTime(2026, 4, 1)});
  });

  test('a backup without a watchlist restores an empty watchlist', () async {
    await appServices.watchlist.add(film);
    final decoded = jsonDecode(await appServices.exportUserDataBackup()) as Map<String, dynamic>;
    decoded.remove('watchlist');
    await appServices.restoreUserDataBackup(jsonEncode(decoded));
    expect(appServices.watchlist.entries, isEmpty);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/app_services_persistence_test.dart --plain-name "AppServices watchlist"`
Expected: FAIL — `watchlist`, `libraryStatusOf`, `LibraryToggleResult` non definiti.

- [ ] **Step 3: Implement in `app_services.dart`**
  - Campo: `late final WatchlistService watchlist = WatchlistService(store: () => userDataStore, flushIfIdle: _maybeFlush, isInCatalogue: isInCatalogue);`
  - `addToCatalogue`: subito dopo `_catalogue.add(localItem)` (`:123`), `await watchlist.remove(localItem);`. Nessun altro metodo di aggiunta cambia.
  - `toggleCatalogueItem`: in catalogo → `removeFromCatalogue` → `removedFromCatalogue`; `Film` → `addToCatalogueWithWatchTime` → `addedToCatalogue`; altrimenti `switch (await watchlist.add(item))`: `added` → `addedToWatchlist`, `alreadyPresent` → `alreadyOnWatchlist`, `alreadyInCatalogue` → `addedToCatalogue` (catalogata nel frattempo da un'altra azione).
  - `libraryStatusOf`: `isInCatalogue` → `catalogue`, poi `watchlist.contains` → `watchlist`, altrimenti `none`.
  - `initialize`: dopo `_history.replaceAll` (`:555`), `await watchlist.loadFrom(store);`.
  - `clearAllData`: dopo `_alerts.clear()` (`:756`), `watchlist.clear();`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services/app_services_persistence_test.dart`
Expected: PASS (nuovo gruppo + tutti i gruppi esistenti).

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/library_status.dart lib/core/services/app_services.dart test/services/app_services_persistence_test.dart
git commit -m "Move titles from the watchlist to the catalogue on entry" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: BookmarkOnlyShowsMigration

**Files:**
- Create: `lib/core/services/bookmark_only_shows_migration.dart`
- Modify: `lib/core/services/app_services.dart` (`initialize`, tra `_history.replaceAll` e `watchlist.loadFrom`), `test/services/app_services_persistence_test.dart:416-419`
- Test: `test/services/bookmark_only_shows_migration_test.dart`, `test/services/app_services_persistence_test.dart`

**Interfaces:**
- Consumes: `UserDataStore` (flag + `saveWatchlistEntry`, Task 1), `CatalogueIndex`, `WatchHistoryIndex`, `lastCatalogueActivityByMediaId` (esistenti), `WatchlistEntry`.
- Produces:

```dart
/// One-off move of catalogue shows with no watched episode to the watchlist.
/// Migrated shows lose their followed/favorite tags (the watchlist has none).
class BookmarkOnlyShowsMigration {
  BookmarkOnlyShowsMigration({
    required UserDataStore store,
    required CatalogueIndex catalogue,
    required WatchHistoryIndex history,
    DateTime Function() clock = DateTime.now,
  });
  /// Returns how many shows moved; 0 when the flag is already set.
  Future<int> run();
}
```

- [ ] **Step 1: Write the failing tests**

```dart
// test/services/bookmark_only_shows_migration_test.dart
late FakeUserDataStore store;
late CatalogueIndex catalogue;
late WatchHistoryIndex history;
final now = DateTime(2026, 11, 17);
const film = Film(id: 1, title: 'Film');
const bookmarked = TvShow(id: 2, title: 'Bookmarked', tags: [kFollowedTag, kFavoriteTag]);
const watching = TvShow(id: 3, title: 'Watching');

BookmarkOnlyShowsMigration migration() =>
    BookmarkOnlyShowsMigration(store: store, catalogue: catalogue, history: history, clock: () => now);

setUp(() {
  store = FakeUserDataStore()..catalogue.addAll([film, bookmarked, watching]);
  catalogue = CatalogueIndex()..replaceAll([film, bookmarked, watching]);
  history = WatchHistoryIndex()
    ..add(WatchRecord(mediaId: 3, isFilm: false, episodeId: 301, seasonNumber: 1,
        episodeNumber: 1, durationMinutes: 40, watchedAt: DateTime(2026, 1, 1)));
});

test('moves only shows without watched episodes, dropping their tags', () async {
  expect(await migration().run(), 1);
  expect(catalogue.items.map((i) => i.mediaKey), ['m_1', 't_3']);
  expect(store.catalogue.map((i) => i.mediaKey), ['m_1', 't_3']);
  expect(store.watchlist.single.mediaKey, 't_2');
  expect(store.watchlist.single.item.tags, isEmpty);
  expect(store.watchlist.single.addedAt, now);
  expect(store.watchlistMigrationDone, isTrue);
});

test('uses the last known activity as addedAt', () async {
  history.add(WatchRecord(mediaId: 2, isFilm: false, durationMinutes: 0, watchedAt: DateTime(2026, 3, 1)));
  await migration().run();
  expect(store.watchlist.single.addedAt, DateTime(2026, 3, 1));
});

test('does nothing once the flag is set', () async {
  store.watchlistMigrationDone = true;
  expect(await migration().run(), 0);
  expect(catalogue.items, hasLength(3));
  expect(store.watchlist, isEmpty);
});
```

```dart
// test/services/app_services_persistence_test.dart, gruppo 'AppServices watchlist'
test('initialize migrates bookmark-only shows and reruns after a backup import', () async {
  store.catalogue.add(const TvShow(id: 80, title: 'Old Bookmark'));
  await appServices.initialize(userDataStore: store);
  expect(appServices.isInCatalogue(const TvShow(id: 80, title: '')), isFalse);
  expect(appServices.watchlist.contains(const TvShow(id: 80, title: '')), isTrue);
  expect(store.watchlistMigrationDone, isTrue);

  store.catalogue.add(const TvShow(id: 81, title: 'Bookmark In Backup'));
  final backup = await appServices.exportUserDataBackup();
  await appServices.restoreUserDataBackup(backup);

  expect(appServices.isInCatalogue(const TvShow(id: 81, title: '')), isFalse);
  expect(appServices.watchlist.contains(const TvShow(id: 81, title: '')), isTrue);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/services/bookmark_only_shows_migration_test.dart test/services/app_services_persistence_test.dart --plain-name "migrat"`
Expected: FAIL — `BookmarkOnlyShowsMigration` non definito.

- [ ] **Step 3: Implement**
  - `run()` in `bookmark_only_shows_migration.dart`: esce con `0` se `loadWatchlistMigrationDone()`; per ogni `catalogue.tvShows` con `history.episodeCountFor(id) == 0`, nell'ordine dello spec: `saveWatchlistEntry(WatchlistEntry(item: show.copyWithTags(const []), addedAt: lastCatalogueActivityByMediaId(history.records)[show.mediaKey] ?? clock()))`, poi `removeCatalogueItem(show)` e `catalogue.remove(show)`; infine `saveWatchlistMigrationDone()` e `flush()`. Un crash a metà lascia la voce in entrambi: la pulizia di `loadFrom` e il flag non scritto la risistemano al lancio successivo.
  - `initialize`: tra `_history.replaceAll` e `watchlist.loadFrom`, `BookmarkOnlyShowsMigration(store: store, catalogue: _catalogue, history: _history).run()` dentro `try/catch` con `debugPrint` (un errore non blocca l'avvio; il flag resta assente e si ritenta).
  - Test esistente `importBackgroundCheckResult` (`:416-419`): aggiungi `store.watchlistMigrationDone = true;` prima di `initialize`. Il test verifica gli avvisi di una serie seguita a 0 episodi, stato che la migrazione ora sposta in watchlist; il flag preserva il suo scopo.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/services`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/bookmark_only_shows_migration.dart lib/core/services/app_services.dart test/services/bookmark_only_shows_migration_test.dart test/services/app_services_persistence_test.dart
git commit -m "Migrate bookmark-only shows to the watchlist once" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Refactor del Catalogo (nessun cambio di comportamento)

**Files:**
- Create: `lib/presentation/screens/catalogue/catalogue_view.dart`, `lib/presentation/widgets/media_search_field.dart`, `lib/presentation/widgets/active_media_filter_chips.dart`, `test/widgets/catalogue_screen_test.dart`
- Modify: `lib/presentation/screens/catalogue/catalogue_screen.dart:1-441`, `lib/presentation/widgets/media_filters.dart:54,73`, `lib/presentation/screens/search/search_screen.dart:441`, `test/core/catalogue_activity_test.dart:145,160`

**Interfaces:**
- Consumes: `FakeUserDataStore` (Task 1).
- Produces:
  - `applyMediaFilters(Iterable<CatalogueItem> items, {required MediaFilter mediaFilter, required MediaSortOption sortOption, Map<String, DateTime> recencyByMediaKey = const {}})`
  - `class CatalogueView extends StatefulWidget { const CatalogueView({super.key, this.isActive = true}); final bool isActive; }` — corpo attuale (`catalogue_screen.dart:26-440`) senza `Scaffold`/`SafeArea`/`AppPageHeader`
  - `class MediaSearchField extends StatelessWidget { const MediaSearchField({super.key, required String hintText, required ValueChanged<String> onChanged, required bool filtersActive, required VoidCallback onFiltersPressed}); }` — la `Row` di `:246-271` (`TextField` + 8 dp + `MediaFiltersButton(compact: true)`); il padding resta al chiamante
  - `class ActiveMediaFilterChips extends StatelessWidget { const ActiveMediaFilterChips({super.key, required MediaFilter mediaFilter, required MediaSortOption sortOption, required VoidCallback onClearMediaFilter, required VoidCallback onClearSort, List<Widget> extraChips = const []}); }` — ordine: chip tipo, `extraChips`, chip ordinamento (come `:293-328`)
  - `CatalogueScreen` = `Scaffold(SafeArea(Column[AppPageHeader, Expanded(CatalogueView(isActive: widget.isActive))]))`

- [ ] **Step 1: Write the characterization test** (deve passare **prima** del refactor: fissa il comportamento attuale)

```dart
// test/widgets/catalogue_screen_test.dart
final appServices = AppServices();
late FakeUserDataStore store;

Future<void> pumpCatalogue(WidgetTester tester) async {
  await appServices.initialize(userDataStore: store);
  await tester.pumpWidget(const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CatalogueScreen(),
  ));
  await tester.pumpAndSettle();
}

setUp(() => store = FakeUserDataStore()
  ..watchlistMigrationDone = true
  ..catalogue.addAll(const [Film(id: 1, title: 'Alpha'), Film(id: 2, title: 'Beta')]));

testWidgets('search narrows the catalogue by title', (tester) async {
  await pumpCatalogue(tester);
  await tester.enterText(find.byType(TextField), 'alp');
  await tester.pumpAndSettle();
  expect(find.text('Alpha'), findsOneWidget);
  expect(find.text('Beta'), findsNothing);
});

testWidgets('the type filter shows a chip that clears it', (tester) async {
  await pumpCatalogue(tester);
  await tester.tap(find.text('Total Watch Time'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Films').first);
  await tester.pumpAndSettle();
  expect(find.byType(InputChip), findsOneWidget);
  await tester.tap(find.descendant(of: find.byType(InputChip), matching: find.byType(Icon)).last);
  await tester.pumpAndSettle();
  expect(find.byType(InputChip), findsNothing);
});

testWidgets('an empty catalogue shows the empty message', (tester) async {
  store.catalogue.clear();
  await pumpCatalogue(tester);
  expect(find.text('Your catalogue is empty'), findsOneWidget);
});
```

- [ ] **Step 2: Run test on the current code**

Run: `flutter test test/widgets/catalogue_screen_test.dart`
Expected: PASS (comportamento attuale fissato).

- [ ] **Step 3: Refactor** — sposta il corpo in `CatalogueView`, estrai `MediaSearchField` e `ActiveMediaFilterChips` (il catalogo passa i 4 chip di stato in `extraChips`), rinomina il parametro in `recencyByMediaKey` in `media_filters.dart:54,73` e nei chiamanti (`catalogue_view.dart`, `search_screen.dart:441`, `test/core/catalogue_activity_test.dart:145,160`). Nessun'altra modifica a `media_filters.dart`.

- [ ] **Step 4: Run tests to verify behaviour is unchanged**

Run: `flutter test test/widgets test/core`, poi `flutter analyze`
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/catalogue/catalogue_screen.dart lib/presentation/screens/catalogue/catalogue_view.dart lib/presentation/widgets/media_search_field.dart lib/presentation/widgets/active_media_filter_chips.dart lib/presentation/widgets/media_filters.dart lib/presentation/screens/search/search_screen.dart test/widgets/catalogue_screen_test.dart test/core/catalogue_activity_test.dart
git commit -m "Split the catalogue screen into a shell and a reusable view" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: WatchlistView

**Files:**
- Create: `lib/presentation/screens/catalogue/watchlist_view.dart`, `lib/presentation/screens/catalogue/watchlist_counts_row.dart`, `lib/presentation/widgets/watchlist_snack_bars.dart`, `test/widgets/watchlist_view_test.dart`
- Modify: `lib/presentation/widgets/media_card.dart:10-25,182-192`, `lib/l10n/app_en.arb` (+ generati)

**Interfaces:**
- Consumes: `AppServices().watchlist` (`listenable`, `addedAtByMediaKey`, `entryFor`, `remove`, `restore`), `MediaSearchField`, `ActiveMediaFilterChips`, `applyMediaFilters(..., recencyByMediaKey:)` (Task 7), `showMediaFiltersSheet`, `LazyPagedListView`, `showMediaDetailSheet`.
- Produces:
  - `MediaCard({..., Widget? trailingAction})` — se non `null` sostituisce il bottone segnalibro; chiamanti esistenti invariati
  - `class WatchlistView extends StatefulWidget { const WatchlistView({super.key, this.onFindSomethingToWatch}); final VoidCallback? onFindSomethingToWatch; }`
  - `class WatchlistCountsRow extends StatelessWidget { const WatchlistCountsRow({super.key, required int filmCount, required int tvShowCount, required MediaFilter selectedFilter, required ValueChanged<MediaFilter> onFilterSelected}); }` — tre `ChoiceChip` con etichette `'${l10n.filterAll} $total'`, `'${l10n.statsFilms} $films'`, `'${l10n.statsShows} $shows'`
  - `const Duration kWatchlistUndoDuration = Duration(seconds: 6);` e `void showRemovedFromWatchlistSnackBar(ScaffoldMessengerState messenger, AppLocalizations l10n, {required VoidCallback onUndo})` (nasconde la snackbar corrente prima di mostrarla)
  - Chiavi ARB: `removeFromWatchlist`, `removedFromWatchlist`, `undo`, `watchlistSearchHint`, `watchlistEmptyTitle`, `watchlistEmptyBody`, `watchlistEmptyCta`, `watchlistNoFilterMatches` (testi esatti dello spec §6.3)

- [ ] **Step 1: Write the failing test**

```dart
// test/widgets/watchlist_view_test.dart
final appServices = AppServices();
late FakeUserDataStore store;
const dune = Film(id: 1, title: 'Dune');
const severance = TvShow(id: 2, title: 'Severance');
const arrival = Film(id: 3, title: 'Arrival');

/// Seeds store.watchlist with [entries], runs appServices.initialize(userDataStore: store), then pumps
/// MaterialApp(localizations, home: Scaffold(body: WatchlistView(onFindSomethingToWatch: onFind))) and settles.
Future<void> pumpView(WidgetTester tester, {List<WatchlistEntry> entries = const [], VoidCallback? onFind}) async {
  // body as described above
}

setUp(() => store = FakeUserDataStore()..watchlistMigrationDone = true);

final seeded = [
  WatchlistEntry(item: dune, addedAt: DateTime(2026, 1, 1)),
  WatchlistEntry(item: severance, addedAt: DateTime(2026, 3, 1)),
  WatchlistEntry(item: arrival, addedAt: DateTime(2026, 2, 1)),
];

testWidgets('lists the most recently added first', (tester) async {
  await pumpView(tester, entries: seeded);
  final dy = [for (final t in ['Severance', 'Arrival', 'Dune']) tester.getTopLeft(find.text(t)).dy];
  expect(dy[0] < dy[1] && dy[1] < dy[2], isTrue);
});

testWidgets('counts row filters by type', (tester) async {
  await pumpView(tester, entries: seeded);
  expect(find.text('All 3'), findsOneWidget);
  expect(find.text('Films 2'), findsOneWidget);
  expect(find.text('Shows 1'), findsOneWidget);
  await tester.tap(find.text('Films 2'));
  await tester.pumpAndSettle();
  expect(find.text('Severance'), findsNothing);
  expect(find.text('Dune'), findsOneWidget);
});

testWidgets('search filters and shows a no-match state', (tester) async {
  await pumpView(tester, entries: seeded);
  expect(find.widgetWithText(TextField, 'Search watchlist...'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'dun');
  await tester.pumpAndSettle();
  expect(find.text('Dune'), findsOneWidget);
  expect(find.text('Arrival'), findsNothing);
  await tester.enterText(find.byType(TextField), 'zzz');
  await tester.pumpAndSettle();
  expect(find.text('No titles match your filters'), findsOneWidget);
});

testWidgets('empty state calls back to Search', (tester) async {
  var called = false;
  await pumpView(tester, onFind: () => called = true);
  expect(find.text('Your watchlist is empty'), findsOneWidget);
  expect(find.text('Save films and shows you want to watch from their details.'), findsOneWidget);
  expect(find.byIcon(Icons.playlist_add), findsOneWidget);
  await tester.tap(find.text('Find something to watch'));
  expect(called, isTrue);
});

testWidgets('removing offers a 6 s Undo that restores the original date', (tester) async {
  await pumpView(tester, entries: seeded);
  await tester.tap(find.descendant(
    of: find.ancestor(of: find.text('Dune'), matching: find.byType(MediaCard)),
    matching: find.byTooltip('Remove from watchlist'),
  ));
  await tester.pumpAndSettle();
  expect(find.text('Dune'), findsNothing);
  expect(find.text('Removed from watchlist'), findsOneWidget);
  expect(tester.widget<SnackBar>(find.byType(SnackBar)).duration, const Duration(seconds: 6));
  expect(find.byIcon(Icons.favorite_border), findsNothing);

  await tester.tap(find.text('Undo'));
  await tester.pumpAndSettle();
  expect(find.text('Dune'), findsOneWidget);
  expect(appServices.watchlist.addedAtByMediaKey['m_1'], DateTime(2026, 1, 1));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/watchlist_view_test.dart`
Expected: FAIL — `WatchlistView` non definito.

- [ ] **Step 3: Implement**
  - Chiavi in `app_en.arb`, poi `flutter gen-l10n`.
  - `MediaCard.trailingAction` (additivo).
  - `WatchlistView`: `ValueListenableBuilder` su `watchlist.listenable`; lista vuota → empty state (icona `Icons.playlist_add`, titolo, testo, `FilledButton.tonal` "Find something to watch" → `onFindSomethingToWatch`); altrimenti `WatchlistCountsRow`, `MediaSearchField` (hint `watchlistSearchHint`, badge attivo se `sortOption != none`), `ActiveMediaFilterChips` senza `extraChips`, poi `LazyPagedListView` o testo `watchlistNoFilterMatches`. Filtro titolo come nel catalogo, poi `applyMediaFilters(..., recencyByMediaKey: watchlist.addedAtByMediaKey)`. Foglio filtri: `showMediaFiltersSheet(context, mediaFilter: _mediaFilter, sortOption: _sortOption, showMediaTypeFilter: false)`, applica solo `sortOption`. Card: `MediaCard(item:, onTap: dettaglio, onToggleFavorite: null, trailingAction: IconButton(icon: Icon(Icons.playlist_add_check), tooltip: l10n.removeFromWatchlist, ...))`. Rimozione: prendi `entryFor` e il `ScaffoldMessenger` prima dell'`await remove`, poi `showRemovedFromWatchlistSnackBar` con Undo → `watchlist.restore(entry)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets`, poi `flutter analyze`
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/catalogue/watchlist_view.dart lib/presentation/screens/catalogue/watchlist_counts_row.dart lib/presentation/widgets/watchlist_snack_bars.dart lib/presentation/widgets/media_card.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/widgets/watchlist_view_test.dart
git commit -m "Add the watchlist view with search, filters and undo" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: LibrarySegmentSwitch e cablaggio della shell

**Files:**
- Create: `lib/presentation/screens/catalogue/library_segment_switch.dart`
- Modify: `lib/presentation/screens/catalogue/catalogue_screen.dart`, `lib/presentation/navigation/main_navigator.dart:32-35`, `lib/l10n/app_en.arb` (+ generati)
- Test: `test/widgets/catalogue_screen_test.dart`

**Interfaces:**
- Consumes: `CatalogueView` (Task 7), `WatchlistView` (Task 8), `watchlist.listenable`, `l10n.statsCatalogueTitleCount` (esistente).
- Produces:
  - `enum LibrarySegment { watched, toWatch }`
  - `class LibrarySegmentSwitch extends StatelessWidget { const LibrarySegmentSwitch({super.key, required LibrarySegment selected, required ValueChanged<LibrarySegment> onChanged, required int watchedCount, required int toWatchCount}); }`
  - `CatalogueScreen({super.key, bool isActive = true, VoidCallback? onFindSomethingToWatch})`
  - Chiavi ARB: `catalogueSegmentWatched`, `catalogueSegmentToWatch`

- [ ] **Step 1: Write the failing tests** (in `catalogue_screen_test.dart`; `pumpCatalogue` accetta `onFindSomethingToWatch`)

```dart
testWidgets('switches segments and keeps each segment search', (tester) async {
  store.watchlist.add(WatchlistEntry(item: const Film(id: 9, title: 'Gamma'), addedAt: DateTime(2026, 1, 1)));
  await pumpCatalogue(tester);
  expect(find.text('Alpha'), findsOneWidget);

  await tester.tap(find.text('To watch'));
  await tester.pumpAndSettle();
  expect(find.text('Gamma'), findsOneWidget);
  expect(find.text('Alpha'), findsNothing);
  await tester.enterText(find.byType(TextField).hitTestable(), 'zzz');
  await tester.pumpAndSettle();

  await tester.tap(find.text('Watched'));
  await tester.pumpAndSettle();
  expect(find.text('Alpha'), findsOneWidget);
  expect(find.text('Beta'), findsOneWidget);
});

testWidgets('segments announce their title count', (tester) async {
  final handle = tester.ensureSemantics();
  store.watchlist.add(WatchlistEntry(item: const Film(id: 9, title: 'Gamma'), addedAt: DateTime(2026, 1, 1)));
  await pumpCatalogue(tester);
  expect(find.bySemanticsLabel('Watched, 2 titles'), findsOneWidget);
  expect(find.bySemanticsLabel('To watch, 1 title'), findsOneWidget);
  handle.dispose();
});

testWidgets('the empty watchlist CTA reaches the navigator callback', (tester) async {
  var called = false;
  await pumpCatalogue(tester, onFindSomethingToWatch: () => called = true);
  await tester.tap(find.text('To watch'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Find something to watch'));
  expect(called, isTrue);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/catalogue_screen_test.dart`
Expected: FAIL — `To watch` non trovato.

- [ ] **Step 3: Implement**
  - Chiavi ARB + `flutter gen-l10n`.
  - `LibrarySegmentSwitch`: `SegmentedButton<LibrarySegment>` a tutta larghezza, una selezione obbligatoria; ogni `ButtonSegment.label` è `Semantics(label: '<etichetta>, ${l10n.statsCatalogueTitleCount(count)}', excludeSemantics: true, child: Text(etichetta))`.
  - Shell: stato `_segment` (default `watched`, ricordato in memoria finché `MainNavigator` tiene viva la tab); sotto `AppPageHeader` lo switch (conteggio "To watch" da `ValueListenableBuilder` su `watchlist.listenable`, "Watched" da `catalogue.length`); corpo `IndexedStack(index: _segment.index, children: [CatalogueView(isActive: widget.isActive && _segment == LibrarySegment.watched), WatchlistView(onFindSomethingToWatch: widget.onFindSomethingToWatch)])` così ogni segmento conserva ricerca e filtri. Back invariato.
  - `MainNavigator`: `CatalogueScreen(isActive: ..., onFindSomethingToWatch: () => _selectTab(MainTab.search.index))`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets`, poi `flutter analyze`
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/catalogue/library_segment_switch.dart lib/presentation/screens/catalogue/catalogue_screen.dart lib/presentation/navigation/main_navigator.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/widgets/catalogue_screen_test.dart
git commit -m "Switch between watched and to-watch in the catalogue tab" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: WatchlistButton nel dettaglio

**Files:**
- Create: `lib/presentation/widgets/watchlist_button.dart`, `test/widgets/watchlist_button_test.dart`
- Modify: `lib/presentation/widgets/media_detail_sheet.dart:200-244` (film), `:258-319` (episodio), `:321-388` (stagione), `:534-538` (stato), `:750-777` (bottoni), `lib/presentation/widgets/watchlist_snack_bars.dart`, `lib/l10n/app_en.arb` (+ generati)
- Test: `test/widgets/watchlist_button_test.dart`, `test/widgets/media_detail_sheet_test.dart`

**Interfaces:**
- Consumes: `libraryStatusOf`, `LibraryStatus` (Task 5), `watchlist.add/remove/restore/entryFor` (Task 4), `showRemovedFromWatchlistSnackBar` (Task 8).
- Produces:
  - `enum WatchlistButtonState { available, onWatchlist, inCatalogue }`
  - `WatchlistButtonState watchlistButtonStateFor(LibraryStatus status)`
  - `class WatchlistButton extends StatelessWidget { const WatchlistButton({super.key, required WatchlistButtonState state, VoidCallback? onPressed}); }` — in `inCatalogue` è sempre disabilitato, qualunque `onPressed`
  - `void showWatchlistSnackBar(ScaffoldMessengerState messenger, String message)` in `watchlist_snack_bars.dart` (nasconde la corrente prima)
  - Chiavi ARB: `addToWatchlist`, `onWatchlist`, `addedToWatchlist`, `movedToCatalogue`, `alreadyInCatalogueHint`

- [ ] **Step 1: Write the failing tests**

```dart
// test/widgets/watchlist_button_test.dart
Future<void> pump(WidgetTester tester, WatchlistButtonState state, VoidCallback onPressed) => tester.pumpWidget(
    MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WatchlistButton(state: state, onPressed: onPressed))));

test('maps library status to button state', () {
  expect(watchlistButtonStateFor(LibraryStatus.none), WatchlistButtonState.available);
  expect(watchlistButtonStateFor(LibraryStatus.watchlist), WatchlistButtonState.onWatchlist);
  expect(watchlistButtonStateFor(LibraryStatus.catalogue), WatchlistButtonState.inCatalogue);
});

testWidgets('available adds, onWatchlist shows the checked icon', (tester) async {
  var taps = 0;
  await pump(tester, WatchlistButtonState.available, () => taps++);
  expect(find.byIcon(Icons.playlist_add), findsOneWidget);
  await tester.tap(find.text('Add to Watchlist'));
  expect(taps, 1);
  await pump(tester, WatchlistButtonState.onWatchlist, () => taps++);
  expect(find.byIcon(Icons.playlist_add_check), findsOneWidget);
  expect(find.text('On Watchlist'), findsOneWidget);
  expect(tester.getSize(find.byType(WatchlistButton)).height, greaterThanOrEqualTo(48));
});

testWidgets('inCatalogue is disabled and explains why', (tester) async {
  final handle = tester.ensureSemantics();
  var taps = 0;
  await pump(tester, WatchlistButtonState.inCatalogue, () => taps++);
  expect(find.byIcon(Icons.playlist_add), findsOneWidget);
  await tester.tap(find.text('Add to Watchlist'));
  expect(taps, 0);
  expect(tester.getSemantics(find.byType(WatchlistButton)),
      containsSemantics(label: 'Add to Watchlist', hint: 'Already in your catalogue', isButton: true, hasEnabledState: true, isEnabled: false));
  handle.dispose();
});
```

```dart
// test/widgets/media_detail_sheet_test.dart, nuovo group('watchlist button')
// _FilmStubTmdbService extends TmdbService: getMediaDetails → MediaDetails(title: item.title, isFilm: true, runtimeMinutes: 120).
// _WatchlistShowStubTmdbService extends _SheetStubTmdbService: getTvShowSummary → const TvShowSummary(numberOfSeasons: 2),
//   getSeasonEpisodes → const [] (il refresh degli avvisi dopo l'episodio non va in rete).
// setUp: store = FakeUserDataStore()..watchlistMigrationDone = true.
/// Runs appServices.initialize(userDataStore: store), sets appServices.tmdbService = tmdb, pumps
/// MaterialApp(localizations, home: Scaffold(body: MediaDetailSheet(item: item))) and settles.
Future<void> pumpDetail(WidgetTester tester, CatalogueItem item, TmdbService tmdb) async {
  // body as described above
}
WatchlistButton button(WidgetTester t) => t.widget<WatchlistButton>(find.byType(WatchlistButton));

// Review Focus 5
testWidgets('a catalogued film without a watch record cannot be watchlisted', (tester) async {
  const film = Film(id: 900, title: 'No Runtime Film');
  store.catalogue.add(film);
  await pumpDetail(tester, film, _FilmStubTmdbService());
  expect(button(tester).state, WatchlistButtonState.inCatalogue);
});

testWidgets('adds a film and removes it with Undo', (tester) async {
  await pumpDetail(tester, const Film(id: 901, title: 'Fresh Film'), _FilmStubTmdbService());
  await tester.ensureVisible(find.text('Add to Watchlist'));
  await tester.tap(find.text('Add to Watchlist'));
  await tester.pumpAndSettle();
  expect(find.text('Added to watchlist'), findsOneWidget);
  expect(button(tester).state, WatchlistButtonState.onWatchlist);
  final addedAt = appServices.watchlist.addedAtByMediaKey['m_901'];

  await tester.tap(find.text('On Watchlist'));
  await tester.pumpAndSettle();
  expect(find.text('Removed from watchlist'), findsOneWidget);
  await tester.tap(find.text('Undo'));
  await tester.pumpAndSettle();
  expect(appServices.watchlist.addedAtByMediaKey['m_901'], addedAt);
  expect(button(tester).state, WatchlistButtonState.onWatchlist);
});

testWidgets('Mark as Watched on a watchlisted film says it moved', (tester) async {
  const film = Film(id: 902, title: 'Queued Film');
  store.watchlist.add(WatchlistEntry(item: film, addedAt: DateTime(2026, 1, 1)));
  await pumpDetail(tester, film, _FilmStubTmdbService());
  await tester.ensureVisible(find.text('Mark as Watched'));
  await tester.tap(find.text('Mark as Watched'));
  await tester.pumpAndSettle();
  expect(find.text('Moved from watchlist to your catalogue'), findsOneWidget);
  expect(find.text('Added to catalogue'), findsNothing);
  expect(button(tester).state, WatchlistButtonState.inCatalogue);
  expect(appServices.watchlist.contains(const Film(id: 902, title: '')), isFalse);
});

testWidgets('adding an episode of a watchlisted show says it moved', (tester) async {
  store.watchlist.add(WatchlistEntry(item: show, addedAt: DateTime(2026, 1, 1)));
  await pumpDetail(tester, show, _WatchlistShowStubTmdbService());
  await tester.tap(find.text('Season 1'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Add episode to catalogue').first);
  await tester.pumpAndSettle();
  expect(find.text('Moved from watchlist to your catalogue'), findsOneWidget);
  expect(button(tester).state, WatchlistButtonState.inCatalogue);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/watchlist_button_test.dart test/widgets/media_detail_sheet_test.dart`
Expected: FAIL — `WatchlistButton` non definito.

- [ ] **Step 3: Implement**
  - Chiavi ARB + `flutter gen-l10n`.
  - `WatchlistButton`: `SizedBox(width: double.infinity, child: OutlinedButton.icon(...))` come Follow/Favorite; icone ed etichette dalla tabella dello spec §6.3; in `inCatalogue` `onPressed: null` e `MergeSemantics(child: Semantics(hint: l10n.alreadyInCatalogueHint, child: ...))` perché hint e stato del bottone stiano in un solo nodo.
  - `media_detail_sheet.dart`:
    - `Future<void> _toggleWatchlist()`: `onWatchlist` → prendi `entryFor` e il messenger, `remove`, `showRemovedFromWatchlistSnackBar` con Undo (`restore` e poi `setState` se `mounted`); `available` → `add`, `showWatchlistSnackBar(messenger, l10n.addedToWatchlist)`; poi `_notifyWatchTimeChanged()`.
    - In `build`: `final libraryStatus = _appServices.libraryStatusOf(widget.item);` passato a `_buildSheetList`; bottone `WatchlistButton(state: watchlistButtonStateFor(libraryStatus), onPressed: _guarded(_toggleWatchlist))`.
    - Posizione film: dopo "Mark as Watched", `SizedBox(height: 12)`, `WatchlistButton`, poi (se `filmWatched`) `SizedBox(height: 12)` + Favorite. Serie: `SizedBox(height: 20)`, `WatchlistButton`, poi `if (inCatalogue)` `SizedBox(height: 12)` + Follow + `SizedBox(height: 12)` + Favorite.
    - Film, episodio, stagione: leggi `final wasOnWatchlist = _appServices.libraryStatusOf(...) == LibraryStatus.watchlist;` **prima** dell'azione; a successo mostra `l10n.movedToCatalogue` se `wasOnWatchlist` (al posto di `addedToCatalogue` per il film; in più rispetto a oggi per episodio e stagione, che oggi non mostrano snackbar). Nessun Undo.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets`, poi `flutter analyze`
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/watchlist_button.dart lib/presentation/widgets/watchlist_snack_bars.dart lib/presentation/widgets/media_detail_sheet.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/widgets/watchlist_button_test.dart test/widgets/media_detail_sheet_test.dart
git commit -m "Add the watchlist button to the detail sheet" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Snackbar del segnalibro in Cerca

**Files:**
- Create: `lib/presentation/screens/search/library_toggle_message.dart`, `test/widgets/library_toggle_message_test.dart`
- Modify: `lib/presentation/screens/search/search_screen.dart:457-478`, `lib/l10n/app_en.arb` (+ generati)

**Interfaces:**
- Consumes: `Future<LibraryToggleResult> toggleCatalogueItem`, `libraryStatusOf`, `LibraryStatus`, `LibraryToggleResult` (Task 5).
- Produces:
  - `String libraryToggleMessage(LibraryToggleResult result, {required LibraryStatus statusBefore, required AppLocalizations l10n})`
  - Chiavi ARB: `showAddedToWatchlist`, `alreadyOnWatchlist`

- [ ] **Step 1: Write the failing test**

```dart
final l10n = lookupAppLocalizations(const Locale('en'));

test('maps each toggle outcome to its snackbar text', () {
  String msg(LibraryToggleResult r, [LibraryStatus before = LibraryStatus.none]) =>
      libraryToggleMessage(r, statusBefore: before, l10n: l10n);
  expect(msg(LibraryToggleResult.addedToCatalogue), 'Added to catalogue');
  expect(msg(LibraryToggleResult.addedToCatalogue, LibraryStatus.watchlist), 'Moved from watchlist to your catalogue');
  expect(msg(LibraryToggleResult.removedFromCatalogue, LibraryStatus.catalogue), 'Removed from catalogue');
  expect(msg(LibraryToggleResult.addedToWatchlist),
      'Added to your watchlist. Mark an episode as watched to add it to your catalogue.');
  expect(msg(LibraryToggleResult.alreadyOnWatchlist, LibraryStatus.watchlist), 'Already on your watchlist');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/library_toggle_message_test.dart`
Expected: FAIL — `libraryToggleMessage` non definito.

- [ ] **Step 3: Implement**
  - Chiavi ARB + `flutter gen-l10n`.
  - `libraryToggleMessage`: `switch` esaustivo sul risultato.
  - `_toggleItem`: `final statusBefore = _appServices.libraryStatusOf(item);` conferma solo se `statusBefore == LibraryStatus.catalogue`; `final result = await _appServices.toggleCatalogueItem(item);` dopo il check `mounted` la snackbar usa `libraryToggleMessage(result, statusBefore: statusBefore, l10n: l10n)`. `MediaCard` e `isBookmarked: inCatalogue` invariati (segnalibro vuoto per le serie in watchlist).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets`, poi `flutter analyze`
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/search/library_toggle_message.dart lib/presentation/screens/search/search_screen.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/widgets/library_toggle_message_test.dart
git commit -m "Explain where the search bookmark put each title" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 12: Verifica finale

**Files:** nessuno (solo eventuali correzioni ai file dei task precedenti).

- [ ] **Step 1: Controlla le stringhe** — `lib/l10n/app_en.arb` contiene le 17 chiavi dello spec §6.3 con i testi esatti; `flutter gen-l10n` non produce differenze (`git status` pulito su `lib/l10n/`).
- [ ] **Step 2: Analisi statica** — Run: `flutter analyze` → Expected: `No issues found!`.
- [ ] **Step 3: Suite completa** — Run: `flutter test` → Expected: `All tests passed!`.
- [ ] **Step 4: Controlli di vincolo** — `git diff main -- lib/core/constants/storage_constants.dart` mostra solo le due costanti nuove (`storageSchemaVersion` resta `3`); `_backupVersion = 2` e `_backupMetaKeys` invariati; `pubspec.yaml` invariato.
- [ ] **Step 5: Da segnalare all'utente** (non verificabile con i test): migrazione su dati reali, CTA dell'empty state da `MainNavigator`, text scaling 200% sui bottoni impilati, TalkBack/VoiceOver sul segmento; il repo non ha un changelog: la perdita dei tag followed/favorite delle serie migrate (spec §7.2) va riportata nelle note di rilascio.
- [ ] **Step 6: Commit** — solo se gli step precedenti hanno richiesto correzioni, con `git add` dei file corretti e messaggio all'imperativo che descrive la correzione + riga `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
