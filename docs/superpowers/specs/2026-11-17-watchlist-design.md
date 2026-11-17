# Design watchlist iz-show-time

- **Data**: 2026-11-17
- **Branch**: `feature/watchlist`
- **Stato**: design rivisto dopo il feedback dell'utente, in attesa di approvazione.
- **Convenzione**: le voci marcate **(scelta di Claude)** non sono state decise dall'utente e possono essere riviste dal builder, motivandolo.

## 1. Intento e perché

- Oggi il **Catalogo** contiene solo titoli **visti**: film segnati come visti, serie con episodi visti.
- Manca un posto per i titoli **da vedere**. La watchlist colma il vuoto.
- La watchlist è uno stato **alternativo** al catalogo, non un sottoinsieme:
  - un titolo è in watchlist **oppure** in catalogo, mai in entrambi;
  - watchlist → catalogo: automatico quando il titolo entra nel catalogo (visto, episodio, stagione);
  - catalogo → watchlist: non ammesso.
- Il passaggio è **unidirezionale**.
- **Invariante permanente** (non solo migrazione): in catalogo stanno solo serie con almeno un episodio visto; le serie senza episodi visti stanno in watchlist.

## 2. Obiettivi / Non obiettivi / Anti-obiettivi

### Obiettivi

- Bottone watchlist nel dettaglio (`lib/presentation/widgets/media_detail_sheet.dart`).
- Vista watchlist con ricerca, filtro tipo (film/serie) e ordinamento coerenti con il catalogo.
  - Senza i filtri di stato del catalogo: preferiti, in corso, non seguite, in pari.
- Logica esistente intatta: statistiche, filtri del catalogo, notifiche nuovi episodi, sync stato messa in onda.
- Componenti piccoli e isolati (SOLID/SRP).
- Nessuna nuova libreria di state management. Stile esistente: singleton `AppServices`, servizi iniettati come `EpisodeAlertsService`, `ValueNotifier`, `setState`.

### Non obiettivi

- Rinominare la tab "Catalogue".
- Undo sul passaggio watchlist → catalogo.
- "Segna come visto" rapido dalle card.
- Ordinamento per data di uscita o filtro "in uscita".
- Badge watchlist nel carosello Home.
- Swipe-to-dismiss (possibile in seguito).
- Modificare l'icona o la semantica del segnalibro in Cerca.
- Aggiungere alla watchlist da card senza aprire il dettaglio (azione watchlist dedicata; il segnalibro sulle serie segue la decisione 3).

### Anti-obiettivi

- Watchlist che altera statistiche o conteggi del catalogo, genera notifiche o chiamate TMDB di sync.
- Codice di filtri/ricerca duplicato tra catalogo e watchlist.
- Bump di `StorageConstants.storageSchemaVersion`: `readSnapshot` dell'isolate in background restituirebbe `null` (`lib/data/repositories/hive_user_data_store.dart:94`).

## 3. Vincoli

- **Unico ingresso nel catalogo**: ogni aggiunta passa da `addToCatalogue` (`lib/core/services/app_services.dart:115`). Chiamanti:
  - `addToCatalogueWithWatchTime` (`:264`)
  - `toggleCatalogueItem` (`:290`)
  - `addSeasonToCatalogue` (`:374`)
  - `markFilmWatched` (`:433`)
  - `markEpisodeWatched` (`:471`)
- **Serie a 0 episodi in catalogo**: oggi l'unico percorso che le crea è `toggleCatalogueItem` (`app_services.dart:281-293`, ramo non-Film → `addToCatalogue`).
  - `unmarkEpisodeWatched` (`:493`) e `removeSeasonFromCatalogue` (`:392`) non lasciano serie a 0 episodi: la UI (`media_detail_sheet.dart:267` e `:348`, `wouldRemoveLastCataloguedEpisodes`) chiede conferma e rimuove l'intera serie. L'invariante regge senza toccarli.
  - `addToCatalogue` **non** deve rifiutare serie a 0 episodi: `markEpisodeWatched` e `addSeasonToCatalogue` la chiamano prima di registrare gli episodi.
- **Chiave dei titoli**: `mediaKey` (`mediaKeyOf`, `lib/data/models/catalogue_item.dart:12`); film e serie con lo stesso id TMDB sono distinti.
- **Persistenza**: Hive con valori JSON-string; nessuna migrazione di schema ammessa (vedi anti-obiettivi).
- **Isolate in background**: rilegge lo store a ogni run; non deve vedere né usare la watchlist.
- **Film in catalogo senza `WatchRecord`**: esistono (`app_services.dart:268-276`, runtime TMDB assente o `ApiException`). Lo stato "in catalogo" non coincide con "film visto".
- **Backup**: i file esistenti (`_backupVersion = 2`, `hive_user_data_store.dart:43`) devono restare importabili.
- **Test**: fake scritti a mano, nessun mock.

## 4. Approcci considerati

Analisi di un agente architetto Flutter e di un agente UX: concordi sul modello dati, divergenti sull'ingresso.

### Modello dati

- **A) Tag riservato `kWatchlistTag` nel catalogo + filtro.** Scartato. Unico vantaggio: backup gratis. Rotture:
  - `isInCatalogue` (`app_services.dart:108`) diventa vero per la watchlist, quindi:
    - `toggleCatalogueItem` (`:281`) rimuove invece di aggiungere;
    - `addToCatalogueWithWatchTime` (`:261`) esce subito: un film in watchlist non registra tempo di visione;
    - `markFilmWatched`, `markEpisodeWatched`, `addSeasonToCatalogue` saltano `addToCatalogue`.
  - `addToCatalogue` segue le serie di default (`:121`): notifiche spurie.
  - Statistiche gonfiate (`lib/presentation/screens/catalogue/catalogue_screen.dart:218-234`).
  - Il filtro "In corso" guarda solo lo stato TMDB (`show_in_progress.dart:39`): includerebbe titoli non visti.
  - Sync TMDB extra (`app_services.dart:208`).
- **B) Entità separata.** **Scelto.** Concetto di dominio diverso; un solo aggancio in `addToCatalogue`.

### Ingresso UI

- **Quinta tab.** Scartata: due icone "libreria" affiancate si confondono.
- **`SegmentedButton` nella tab Catalogo.** **Scelto dall'utente.**

## 5. Decisioni dell'utente

1. Opzione B: watchlist come entità separata.
2. Ingresso: `SegmentedButton` "Watched | To watch" in cima alla tab Catalogo; le tab restano 4.
3. Segnalibro in Cerca:
   - resta "aggiungi al catalogo": icona e comportamento attuali (`search_screen.dart:376-387` → `_toggleItem` → `toggleCatalogueItem`); niente card a tre stati, nessuna modifica all'API di `MediaCard`;
   - film: invariato (catalogo + tempo di visione via `addToCatalogueWithWatchTime`);
   - serie non in catalogo: va in **watchlist**, non nel catalogo (invariante permanente, sezione 1);
   - le serie "bookmark-only" (0 episodi, `app_services.dart:306`) già in catalogo migrano **una volta** in watchlist.
4. Rimuovendo dal catalogo un titolo (o l'ultimo episodio di una serie) il titolo sparisce del tutto; non torna in watchlist (comportamento attuale invariato).
5. L'aggiunta esplicita alla watchlist si fa **solo** dal dettaglio film/serie (bottom sheet, aperto da Cerca, Home, Catalogo o Watchlist).
6. Nel dettaglio il `WatchlistButton` è **sempre visibile** ma **disabilitato** quando il titolo è in catalogo: un titolo in catalogo non può andare in watchlist.

## 6. Design

### 6.1 Dati

- **Modello** `lib/data/models/watchlist_entry.dart`:
  - `WatchlistEntry({required CatalogueItem item, required DateTime addedAt})`;
  - riusa `Film`/`TvShow`: `MediaCard` e `applyMediaFilters` funzionano senza adattatori;
  - serializzazione: `catalogueItemToStorageJson(item.copyWithTags(const []))` + `'added_at'` in ISO 8601;
  - chiave di storage: `mediaKey`.
- **Box Hive**: `StorageConstants.watchlistBoxName = 'watchlist'` (`lib/core/constants/storage_constants.dart`).
- **Interfaccia**:

  ```dart
  abstract interface class WatchlistStore {
    Future<List<WatchlistEntry>> loadWatchlist();
    Future<void> saveWatchlistEntry(WatchlistEntry e);
    Future<void> removeWatchlistEntry(String mediaKey);
  }
  ```

- **Integrazione nello store**:
  - `UserDataStore` (`lib/data/repositories/user_data_store.dart`, oggi `abstract class`) estende/implementa `WatchlistStore`;
  - `HiveUserDataStore` la implementa e aggiorna `open` (`:71-73`), `flush` (`:578`), `clearAll`, `close`;
  - `FakeUserDataStore` (`test/services/app_services_persistence_test.dart:15`, usa `implements`) va aggiornato.

### 6.2 Servizi

- **`WatchlistIndex`** `lib/core/services/watchlist_index.dart`:
  - stato in memoria sul modello di `CatalogueIndex` (`lib/core/services/catalogue_index.dart`);
  - API: `entries`, `items`, `contains(item)`, `Map<String, DateTime> addedAtByMediaKey`, `add`, `remove`, `replaceAll`, `clear`;
  - nessun I/O.
- **`WatchlistService`** `lib/core/services/watchlist_service.dart`, costruito come `EpisodeAlertsService` (`app_services.dart:61-69`):

  ```dart
  WatchlistService({
    required WatchlistStore Function() store,
    required Future<void> Function() flushIfIdle,
    required bool Function(CatalogueItem) isInCatalogue,
  });
  ```

  - `ValueListenable<List<WatchlistEntry>> listenable`
  - `bool contains(CatalogueItem item)`
  - `Future<WatchlistAddResult> add(CatalogueItem item)` con `enum WatchlistAddResult { added, alreadyPresent, alreadyInCatalogue }`; il rifiuto "già in catalogo" vive qui
  - `Future<bool> remove(CatalogueItem item)`: `true` se la voce c'era
  - `Future<void> restore(WatchlistEntry entry)`: per Undo, mantiene l'`addedAt` originale
  - `Future<void> loadFrom(WatchlistStore store)`
  - `void clear()`
- **`AppServices`** (facciata minima, ~10 righe toccate):
  - `late final WatchlistService watchlist` pubblico;
  - **regola di transizione**: in `addToCatalogue`, subito dopo `_catalogue.add`, `await watchlist.remove(localItem)` (idempotente); gli altri metodi di aggiunta non si toccano per la transizione;
  - **`toggleCatalogueItem`** (`:281-293`) instrada e restituisce `LibraryToggleResult` (prima `void`), così Cerca sceglie la snackbar:
    - `Film` → invariato;
    - `TvShow` non in catalogo → `watchlist.add(item)` (`added` → `addedToWatchlist`, `alreadyPresent` → `alreadyOnWatchlist`);
    - titolo in catalogo → rimozione come oggi.

    ```dart
    enum LibraryToggleResult { addedToCatalogue, removedFromCatalogue, addedToWatchlist, alreadyOnWatchlist }
    ```

  - `initialize` (`:547`): carica la watchlist e scarta le voci già in catalogo (difesa da backup incoerenti);
  - `clearAllData` (`:752`): svuota la watchlist.
- **Stato libreria**:
  - `enum LibraryStatus { none, watchlist, catalogue }`;
  - `LibraryStatus libraryStatusOf(CatalogueItem item)` in `AppServices` o come funzione pura in `lib/core/utils`;
  - usato dal dettaglio (e da Cerca per scegliere la snackbar "Moved from watchlist to your catalogue").
- **Migrazione bookmark-only**: vedi 7.2.

### 6.3 UI

#### Shell del Catalogo

- `CatalogueScreen` (`lib/presentation/screens/catalogue/catalogue_screen.dart`, 441 righe) diventa una shell:
  - `AppPageHeader`;
  - `LibrarySegmentSwitch`: `SegmentedButton<LibrarySegment>` con `enum LibrarySegment { watched, toWatch }`;
  - corpo del segmento attivo.
- Il corpo attuale si sposta in `CatalogueView` (segmento `watched`) **senza cambi di comportamento**.
- Nuova `WatchlistView`: `lib/presentation/screens/catalogue/watchlist_view.dart` o `lib/presentation/screens/watchlist/`.
- Segmento ricordato in memoria finché l'app è aperta **(scelta di Claude)**; il back resta invariato (porta a Home).
- Ogni segmento ha il proprio stato di ricerca e filtri.
- `isActive` propagato solo alla vista visibile.

#### Estrazioni riusabili da `CatalogueScreen`

- `MediaSearchField` (da `:244-272`): `TextField` di ricerca + `MediaFiltersButton`.
- `ActiveMediaFilterChips` (da `:282-333`): chip tipo + ordinamento, con parametro `extraChips` per i chip di stato del catalogo.

#### `WatchlistView`

- **Riga conteggi** "All N · Films N · Shows N" che funge da filtro tipo **(scelta di Claude)**: come `CatalogueStatsRow` ma senza watch time.
- **Ricerca**: `MediaSearchField`, hint "Search watchlist...".
- **Filtri**: `showMediaFiltersSheet(context, mediaFilter:, sortOption:)` senza flag di stato e con `showMediaTypeFilter: false` (il tipo lo dà la riga conteggi). Il foglio dei filtri non va modificato.
- **Ordinamento** default "Recently added":
  - `applyMediaFilters(..., lastCatalogueActivityByMediaId: watchlist.addedAtByMediaKey)`;
  - `compareCatalogueByLastActivity` (`lib/core/utils/catalogue_activity.dart:51`) è già generico;
  - refactor senza cambi di comportamento: rinominare il parametro di `applyMediaFilters` (`lib/presentation/widgets/media_filters.dart:54,73`) in `recencyByMediaKey`; chiamanti: `catalogue_screen.dart:125`, `search_screen.dart:441`. È l'unica modifica ammessa a `media_filters.dart`.
- **Lista**: `LazyPagedListView` come il catalogo; aggiornamento via `ValueListenableBuilder` su `watchlist.listenable`.
- **Card**: `MediaCard` con cuore nascosto e azione a destra "Remove from watchlist" (`Icons.playlist_add_check`).
  - Nessun dialog; snackbar con Undo, durata ≥ 6 s **(scelta di Claude)**.
  - Tap → dettaglio.
- **Empty state**: icona `Icons.playlist_add`, titolo, testo, `FilledButton.tonal` "Find something to watch" che porta alla tab Cerca tramite callback da `MainNavigator` (`lib/presentation/navigation/main_navigator.dart`).
- **Nessun risultato** per ricerca/filtri: stato dedicato ("No titles match your filters").

#### `WatchlistButton` nel dettaglio

- File `lib/presentation/widgets/watchlist_button.dart`:

  ```dart
  enum WatchlistButtonState { available, onWatchlist, inCatalogue }

  WatchlistButton({required WatchlistButtonState state, VoidCallback? onPressed})
  ```

  - enum a tre stati **(scelta di Claude)**; mappa `libraryStatusOf(item)`: `none` → `available`, `watchlist` → `onWatchlist`, `catalogue` → `inCatalogue`.
- `OutlinedButton.icon` a tutta larghezza come Follow/Favorite (`media_detail_sheet.dart:875-905`).
- Icone **(scelta di Claude)**: `Icons.playlist_add` / `Icons.playlist_add_check`.
  - Non `bookmark`: già usato dal catalogo.
  - Non `schedule`: già usato per la durata (`media_detail_sheet.dart:693`).
- Stati:

  | Stato | Icona | Etichetta | Azione |
  |---|---|---|---|
  | `available` | `Icons.playlist_add` | "Add to Watchlist" | aggiunge |
  | `onWatchlist` | `Icons.playlist_add_check` | "On Watchlist" | rimuove |
  | `inCatalogue` | `Icons.playlist_add` | "Add to Watchlist" | disabilitato (`onPressed: null`), `Semantics` hint "Already in your catalogue" **(scelta di Claude)** |

- **Visibilità**: sempre. Lo stato deriva da `libraryStatusOf(item)`; non usare `!filmWatched` (vedi vincolo sui film senza `WatchRecord`).
- **Posizione**:
  - film: sotto "Mark as Watched" (`media_detail_sheet.dart:750-765`) e sopra Favorite, spaziatura 12 dp;
  - serie: primo bottone outlined del blocco azioni, sempre visibile, seguito da Follow/Favorite quando la serie è in catalogo (oggi `if (inCatalogue)` a `:772`) **(scelta di Claude)**.
- Usa `_guarded` e le snackbar esistenti.
- **Feedback**:
  - aggiunta: "Added to watchlist";
  - rimozione: "Removed from watchlist" + Undo;
  - passaggio a catalogo (Mark as Watched, aggiunta episodio o stagione mentre è in watchlist): "Moved from watchlist to your catalogue" al posto di "Added to catalogue". La UI legge `libraryStatusOf` **prima** dell'azione per scegliere il messaggio. Nessun Undo **(scelta di Claude)**.

#### Card in Cerca

- Segnalibro invariato (`search_screen.dart:376-387`); `MediaCard` senza modifiche.
- `_toggleItem` sceglie la snackbar dal `LibraryToggleResult` di `toggleCatalogueItem`; per il caso "film in watchlist" legge `libraryStatusOf` **prima** dell'azione, come il dettaglio.

  | Caso | Effetto | Snackbar |
  |---|---|---|
  | Film non in catalogo né in watchlist | catalogo + tempo di visione (invariato) | attuale |
  | Film in watchlist | catalogo; la regola di transizione in `addToCatalogue` lo toglie dalla watchlist | "Moved from watchlist to your catalogue" |
  | Serie non in catalogo né in watchlist | watchlist | "Added to your watchlist. Mark an episode as watched to add it to your catalogue." (`showAddedToWatchlist`) **(scelta di Claude)** |
  | Serie già in watchlist | nessuno | "Already on your watchlist" (`alreadyOnWatchlist`) **(scelta di Claude)** |
  | Titolo in catalogo | rimozione come oggi | attuale |

- Icona: segnalibro vuoto per le serie in watchlist, perché non sono in catalogo **(scelta di Claude)**.

#### Accessibilità

- Target ≥ 48 dp.
- Stato non affidato al solo colore: forma dell'icona + etichetta.
- `Semantics` sul segmento con conteggio (es. "To watch, 14 titles").
- Bottoni impilati per reggere il text scaling.

#### Stringhe (`lib/l10n/app_en.arb`)

| Chiave | Valore |
|---|---|
| `catalogueSegmentWatched` | Watched |
| `catalogueSegmentToWatch` | To watch |
| `addToWatchlist` | Add to Watchlist |
| `onWatchlist` | On Watchlist |
| `removeFromWatchlist` | Remove from watchlist |
| `addedToWatchlist` | Added to watchlist |
| `removedFromWatchlist` | Removed from watchlist |
| `movedToCatalogue` | Moved from watchlist to your catalogue |
| `showAddedToWatchlist` | Added to your watchlist. Mark an episode as watched to add it to your catalogue. |
| `alreadyOnWatchlist` | Already on your watchlist |
| `alreadyInCatalogueHint` | Already in your catalogue |
| `undo` | Undo |
| `watchlistSearchHint` | Search watchlist... |
| `watchlistEmptyTitle` | Your watchlist is empty |
| `watchlistEmptyBody` | Save films and shows you want to watch from their details. |
| `watchlistEmptyCta` | Find something to watch |
| `watchlistNoFilterMatches` | No titles match your filters |

## 7. Migrazione e backup

### 7.1 Storage

- Nessun bump di `storageSchemaVersion`: la box nuova vuota equivale a watchlist vuota.

### 7.2 Migrazione bookmark-only (una tantum)

- Classe separata `lib/core/services/bookmark_only_shows_migration.dart`, eseguita in `initialize` dopo il caricamento dei dati.
- Passi:
  1. Seleziona i `TvShow` in catalogo con `watchedEpisodesCountFor(id) == 0`.
  2. Li aggiunge alla watchlist con `addedAt` = ultima attività nota, altrimenti `now`.
  3. Li rimuove dal catalogo.
  4. Scrive il flag `'watchlist_migration_v1_done'` nella meta box.
- Idempotente: con il flag presente non fa nulla.
- Coerente con l'invariante permanente (sezione 1): dopo la migrazione nessun percorso ricrea serie a 0 episodi in catalogo (vedi 3 e 6.2).
- Effetto collaterale **(scelta di Claude)**: le serie migrate perdono i tag followed/favorite (la watchlist non ha tag). Va accettato e documentato nel changelog.

### 7.3 Backup

- Export/import (`hive_user_data_store.dart:110-171`): sezione opzionale `'watchlist'`.
  - Inclusa in `_replaceBoxContents` e nel rollback `'previous'`.
  - Validata come le altre sezioni.
  - Sezione assente → watchlist vuota: i backup vecchi restano compatibili.
- `_backupVersion` resta 2 **(scelta di Claude)**: un'app vecchia ignora la watchlist invece di rifiutare il file.
- Dopo `importBackupData` il flag della migrazione si azzera e la migrazione si riesegue **(scelta di Claude)**: un backup senza watchlist non reintroduce serie bookmark-only.

## 8. Strategia di test

Stile esistente: fake scritti a mano, nessun mock. Cartelle `test/services`, `test/repositories`, `test/widgets`, `test/core`.

### Unità e servizi

- `watchlist_index_test`: add/replace/remove, `addedAtByMediaKey`, film e serie con stesso id distinti.
- `watchlist_service_test`: rifiuto `alreadyInCatalogue`, idempotenza, `restore` mantiene `addedAt`, persistenza su fake store, chiamata a `flushIfIdle`.
- `bookmark_only_shows_migration_test`: sposta solo serie a 0 episodi; idempotente col flag; non tocca film né serie con episodi.
- `app_services_persistence_test`, nuovo gruppo:
  - ognuno dei percorsi di aggiunta al catalogo rimuove il titolo dalla watchlist (per `toggleCatalogueItem`, solo il ramo film);
  - statistiche e `followedTvShows` non includono la watchlist;
  - pulizia in `initialize` delle voci già in catalogo;
  - `clearAllData` svuota la watchlist;
  - backup andata/ritorno;
  - backup senza sezione → watchlist vuota.
- `hive_user_data_store_test`: box nuova, rollback dell'import su errore nella box watchlist, `clearAll`.

### Widget

- `watchlist_button_test`: icone ed etichette nei tre stati, `Semantics`; disabilitato in `inCatalogue` con hint "Already in your catalogue".
- `media_detail_sheet_test`: bottone presente ma disabilitato se in catalogo; diventa disabilitato dopo Mark as Watched; snackbar "Moved from watchlist to your catalogue".
- `watchlist_view_test`: ricerca, filtro tipo, ordine per data di aggiunta, empty state, rimozione con Undo.
- Segnalibro (`toggleCatalogueItem` e Cerca):
  - su film → catalogo (invariato);
  - su serie non in catalogo → watchlist, `LibraryToggleResult.addedToWatchlist`;
  - su serie in watchlist → `LibraryToggleResult.alreadyOnWatchlist`;
  - nessuna serie a 0 episodi in catalogo dopo qualunque percorso.

### Gate

- `flutter analyze` senza nuovi warning.
- `flutter test` verde.
- Test esistenti del catalogo invariati nel comportamento.

## 9. Scelte lasciate al builder e scelte di Claude

### Lasciate al builder

- Posizione di `libraryStatusOf`: metodo di `AppServices` o funzione pura in `lib/core/utils`.
- Cartella di `WatchlistView`: `screens/catalogue/` o `screens/watchlist/`.
- Forma dell'estensione `WatchlistStore` in `UserDataStore` (`implements` o `extends`), purché i fake restino semplici.

### Scelte di Claude

- Icone `Icons.playlist_add` / `Icons.playlist_add_check`.
- `enum WatchlistButtonState { available, onWatchlist, inCatalogue }` per lo stato del bottone.
- `Semantics` hint "Already in your catalogue" sul bottone disabilitato.
- Bottone watchlist per le serie come primo bottone outlined del blocco azioni.
- Testi delle snackbar del segnalibro sulle serie ("Added to your watchlist. Mark an episode...", "Already on your watchlist") e segnalibro vuoto per le serie in watchlist.
- Snackbar con Undo (≥ 6 s) per le rimozioni dalla watchlist.
- Nessun Undo sulla transizione watchlist → catalogo.
- Segmento ricordato solo in memoria.
- Riga conteggi come filtro tipo nella watchlist.
- `_backupVersion` invariato a 2.
- Migrazione bookmark-only rieseguita dopo l'import di un backup.
- Perdita dei tag followed/favorite per le serie migrate.

## 10. Ordine suggerito di implementazione

1. Dati, store e backup.
2. `WatchlistIndex`, `WatchlistService`, aggancio in `addToCatalogue`.
3. Migrazione bookmark-only.
4. Refactor `CatalogueScreen` in shell + `CatalogueView`; estrazione di `MediaSearchField` e `ActiveMediaFilterChips` (nessun cambio di comportamento).
5. `WatchlistView`.
6. `WatchlistButton` nel dettaglio.
7. Instradamento di `toggleCatalogueItem` (serie → watchlist) e snackbar in Cerca.
8. Stringhe e accessibilità.

## 11. Note dalla revisione

Esito della revisione: nessuna domanda aperta. Fatti verificati nel codice:

- **Migrazione e notifiche**: le serie a 0 episodi oggi non generano avvisi (`new_episode_checker.dart:137-138`). Togliere il tag followed nella migrazione non fa perdere nulla; si perde solo il tag favorite.
- **Flag di migrazione dopo un import**: `importBackupData` riscrive la meta box con le sole `_backupMetaKeys`, e `restoreUserDataBackup` richiama `initialize` (`app_services.dart:780-782`). Basta **non** aggiungere `watchlist_migration_v1_done` a `_backupMetaKeys`, senza codice aggiuntivo.
- **Isolate in background**: con `_readOnly` attivo, `HiveUserDataStore.open()` non deve aprire la box `watchlist`.
- **Decisi in fase di implementazione** (scelta del builder):
  - l'ordine tra migrazione, pulizia dell'invariante e `importBackgroundCheckResult` in `initialize`;
  - `restore` (Undo) di un titolo entrato nel frattempo nel catalogo: viene ignorato.
