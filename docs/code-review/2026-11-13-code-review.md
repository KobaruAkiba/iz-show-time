# Code review iz-show-time

- **Data**: 2026-11-13
- **Branch**: `develop`, commit `009503b` (App version 1.0.2)
- **Modalità**: sola lettura, nessun file modificato durante la review.

**Esito**: 27 rilievi, di cui 0 critici, 4 alti, 11 medi e 12 bassi.
**Da affrontare per primi**: i quattro di gravità Alta. A1 e A2 toccano i dati dell'utente, A3 il consumo di rete in background, A4 blocca la pubblicazione Android.
**`flutter analyze --no-pub`**: nessun errore o warning, 2 info `prefer_const_declarations` (`lib/data/models/media_details.dart:324`, `test/models/watch_record_test.dart:31`).
**`flutter test --no-pub`**: 129 test passati, 1 fallito (rilievo M1).

## 1. Perimetro e contesto

- **Letto per intero**: tutti i sorgenti in `lib/` tranne i due file l10n generati, più `pubspec.yaml`, configurazione Android/iOS, workflow CI e i test coinvolti.
- **Stack**: Flutter 3.44.0 / Dart 3.12.0, Material 3, solo lingua inglese (ARB).
- **Dipendenze chiave**: dio 5.11, hive 2.2.3 + hive_flutter, workmanager, flutter_local_notifications, google_fonts, share_plus, file_selector, flutter_file_dialog.
- **Struttura**: `lib/core`, `lib/data`, `lib/presentation` (4 tab in `IndexedStack`).
- **Stato**: nessuna libreria. `AppServices` è un singleton di 947 righe che fa da repository, use case e stato; le schermate chiamano `setState` a mano e ci sono due `ValueNotifier` (alert, tema).
- **Dati**: TMDB tramite il singleton `DioClient`; cache solo in memoria (`CacheManager`); dati utente in 3 box Hive con valori JSON-string.
- **Background**: Workmanager lancia ogni 2 ore un secondo isolate che riesegue l'intero bootstrap e controlla i nuovi episodi.
- **Segreti**: chiave TMDB passata con `--dart-define`; nessun segreto nel repository né nella history (verificato con grep).

## 2. Rilievi per gravità

Tutti i rilievi sono verificati leggendo il codice, salvo dove è scritto "sospetto" o "stima".

### Critico

Nessuno accertato.

### Alto

#### A1. Film e serie condividono la stessa chiave id

- **Dove**: `lib/core/services/app_services.dart:47,90,100,185-193,713-716`; `lib/data/repositories/hive_user_data_store.dart:178-189`; `lib/presentation/screens/search/search_screen.dart:354`; `lib/presentation/widgets/media_detail_sheet.dart:350`.
- **Difetto**: TMDB usa spazi di ID separati per `movie/` e `tv/`, ma `_catalogueById`, la chiave del box catalogo, `isInCatalogue`, `isFavorite` e `removeFromCatalogue` usano il solo intero. `_removeWatchHistoryForMedia` cancella per `mediaId` senza guardare `isFilm`.
- **Scenario**: con la serie `tv/1402` in catalogo, nella ricerca il film `movie/1402` appare già salvato (la coppia di titoli con questo ID non è stata verificata).
  - Toccando il segnalibro si rimuove la serie con tutti i suoi episodi visti.
  - "Segna come visto" sul film crea un record orfano: `isInCatalogue` è già `true` e il film non viene aggiunto.
- **Soluzione**: chiave composta ovunque, più una migrazione schema v3 che riscrive le chiavi del box.

```dart
typedef MediaKey = ({bool isFilm, int id});
String storageKey(CatalogueItem i) => '${i.isFilm ? 'm' : 't'}_${i.id}';
```

#### A2. Hive aperto da due isolate sugli stessi file

- **Dove**: `lib/core/background/background_entrypoint.dart:16`; `lib/core/bootstrap/app_bootstrap.dart:17-28`; `lib/core/notifications/episode_check_service.dart:33-66`; `lib/core/notifications/app_lifecycle_coordinator.dart:27-29`; `lib/core/services/app_services.dart:626-635`.
- **Difetto**: Hive 2 non supporta l'accesso da più isolate. Il task Workmanager apre e scrive gli stessi box mentre l'isolate UI, se il processo è vivo, li tiene aperti con la propria copia in memoria.
- **Effetto certo**: al resume `reloadNewEpisodeAlertsFromStore()` legge la copia in memoria dell'isolate UI, quindi non vede mai gli alert scritti dal background; alla scrittura successiva li sovrascrive con dati vecchi.
- **Effetto possibile (sospetto, non riprodotto)**: perdita di scritture dopo una compattazione fatta dall'altro isolate, oppure troncamento da crash-recovery se l'apertura coincide con una scrittura in corso.
- **Soluzione**: un solo proprietario dei box. In alternativa:
  1. il background delega il controllo all'isolate UI quando è vivo (`IsolateNameServer` + `SendPort`);
  2. si passa a uno store multi-isolate (hive_ce con `IsolatedHive`, oppure drift/sqlite in WAL);
  3. come minimo, il background scrive in un file dedicato e l'UI fa close+open al resume.

#### A3. Controllo nuovi episodi troppo costoso

- **Dove**: `lib/core/notifications/new_episode_checker.dart:65-84,125`; `lib/data/services/tmdb_service.dart:34-50`; `lib/core/constants/api_constants.dart:27-35`; `lib/core/background/native_background_scheduler.dart:33-46`.
- **Difetto**: per ogni serie seguita, in sequenza, parte 1 richiesta di dettaglio con `append_to_response` completo (`aggregate_credits`, `recommendations`, `similar`, `reviews`…) più 1-2 richieste di stagione. Il checker usa solo `number_of_seasons`, poster e runtime medio. In background la cache è sempre vuota, perché è in memoria e l'isolate è nuovo.
- **Scenario**: con 50 serie seguite sono 100-150 richieste sequenziali ogni 2 ore, anche su rete a consumo (`NetworkType.connected`).
  - Su iOS il task ha circa 30 s e il salvataggio avviene solo alla fine: probabilmente non completa mai (sospetto, non misurato).
  - Il pull-to-refresh in Home aspetta la stessa scansione.
- **Soluzione**:
  1. per il checker chiamare `tv/{id}` senza append, con una chiave di cache propria;
  2. confrontare `last_episode_to_air` con l'ultimo episodio registrato e scaricare la stagione solo se serve;
  3. usare un pool a concorrenza limitata (4-6) tra le serie: oggi il pooling esiste solo tra le stagioni di una serie;
  4. salvare in modo incrementale.

#### A4. Configurazione release Android non pubblicabile

- **Dove**: `android/app/build.gradle.kts:8,21,35`.
- **Difetto**: `applicationId` e `namespace` sono `com.example.iz_show_time_tracker` e la release è firmata con la chiave debug; restano i TODO del template. iOS usa `com.izshowtime.tracker`.
- **Effetto**: la build di release non è pubblicabile.
- **Soluzione**: `applicationId` definitivo, `signingConfigs.release` letto da `key.properties` (già in `.gitignore`), job CI per Android.

### Medio

#### M1. Suite di test rossa su develop

- **Dove**: `test/services/app_services_persistence_test.dart:755-789` contro `lib/core/services/app_services.dart:316-320`.
- **Difetto**: il test "skips airing-soon episodes without resolvable runtime" fallisce con `Expected: <1> Actual: <2>`.
- **Causa**: il commit `b8eccee` ha introdotto il fallback sulla media dei runtime degli altri episodi senza aggiornare il test. Il comportamento di UI e servizio è coerente: è il test a essere obsoleto.
- **Soluzione**: aggiornare il test e aggiungere `flutter analyze` + `flutter test` al workflow; oggi la CI fa solo la build iOS.

#### M2. `forceRefresh` del trending non salta la cache

- **Dove**: `lib/data/services/tmdb_service.dart:334-343`.
- **Difetto**: dentro `_dedupe` il secondo controllo della cache non è protetto da `bypassCache`, a differenza di `_fetchSingle:406`.
- **Scenario**: il pull-to-refresh in Home (`lib/presentation/screens/home/home_screen.dart:122-124`) restituisce il trending in cache per 12 ore.
- **Soluzione**: `if (!bypassCache) { ...cachedAfterWait... }`.

#### M3. La cache serializza e deserializza JSON a ogni accesso, sul thread UI

- **Dove**: `lib/core/cache/cache_manager.dart:27-78`.
- **Difetto**: ogni `put` fa `jsonEncode`, ogni `get` fa `jsonDecode` dell'intero payload. La cache non ha limite di dimensione.
- **Scenario 1**: `syncTvShowAiringStates` (`app_services.dart:171-183`) parte a ogni attivazione del tab Catalogo (`lib/presentation/screens/catalogue/catalogue_screen.dart:69-73`) e decodifica il dettaglio di tutte le serie. Con cache calda la catena di `await` non cede mai il frame.
- **Scenario 2**: `searchLocalCache` (`tmdb_service.dart:90-111`) decodifica tutte le voci a ogni ricerca.
- **Effetto**: scatti proporzionali al catalogo (stima, non profilato).
- **Soluzione**: memorizzare gli oggetti già decodificati (o i `MediaDetails`) con LRU e limite; limitare il sync a una volta per sessione o per TTL; tenere un indice dei titoli per la ricerca locale.

#### M4. `NetworkFeedback.runSilent` silenzia anche gli errori dell'utente

- **Dove**: `lib/core/network/network_feedback.dart:19-35,77`.
- **Difetto**: `_silentDepth` è un contatore statico globale.
- **Scenario**: durante la scansione all'avvio o il sync del catalogo (decine di secondi) l'utente apre una scheda che fallisce e non vede alcuna snackbar. Lo stesso vale per il banner "connessione lenta" (riga 114).
- **Soluzione**: flag legato alla `Zone`.

```dart
static bool get isSilent => Zone.current[#silentNetwork] == true;
static Future<T> runSilent<T>(Future<T> Function() a) =>
    runZoned(a, zoneValues: {#silentNetwork: true});
```

#### M5. Race tra refresh di serie diverse

- **Dove**: `lib/core/services/app_services.dart:647-698` (snapshot alla riga 681; la protezione a epoch delle righe 684-686 copre solo il refresh completo).
- **Difetto**: ogni refresh di una singola serie parte da uno snapshot degli alert e al termine lo riscrive per intero.
- **Scenario**: l'utente registra in rapida successione episodi di due serie.
  1. Il refresh B, partito con lo snapshot vecchio, sovrascrive il risultato di A.
  2. L'alert vecchio di A viene poi potato come già visto.
  3. La serie A sparisce da Continue Watching fino al refresh successivo.
- **Soluzione**: unire al momento del commit (`_newEpisodeAlerts` correnti senza `forShowId`, più il risultato per quella serie), oppure serializzare i refresh in una coda.

#### M6. Home offline nasconde Continue Watching

- **Dove**: `lib/presentation/screens/home/home_screen.dart:170-181`.
- **Difetto**: se il trending fallisce, l'intero corpo diventa `ConnectionErrorView`.
- **Effetto**: gli alert locali, già disponibili, non si vedono.
- **Soluzione**: mostrare l'errore solo nella sezione trending.

#### M7. Scheda serie: tutte le stagioni scaricate all'apertura e un errore le azzera tutte

- **Dove**: `lib/data/services/tmdb_service.dart:253-279`; `lib/presentation/widgets/media_detail_sheet.dart:82-84,112-134`.
- **Difetto**: partono N richieste anche a stagioni chiuse. Si assume una numerazione 1..N contigua. Gli speciali (stagione 0) sono ignorati.
- **Scenario**: una sola stagione in 404 fa fallire `Future.wait` e la UI mostra "nessun episodio".
- **Soluzione**: leggere `seasons[]` dal dettaglio (numero, conteggio, data) e caricare la stagione all'espansione, con errore per singola stagione.

#### M8. Restore del backup non atomico

- **Dove**: `lib/data/repositories/hive_user_data_store.dart:74-90`.
- **Difetto**: i box vengono svuotati prima di validare i contenuti; è controllata solo la forma delle sezioni.
- **Scenario**: con un file dalla struttura valida ma con voci non interpretabili, il catalogo viene cancellato, le voci sono scartate in silenzio al caricamento e compare il messaggio di successo.
- **Soluzione**: validare ogni voce con le factory dei modelli prima di `clear()` e tenere una copia per il rollback.

#### M9. Doppio tap crea record duplicati in memoria

- **Dove**: `lib/core/services/app_services.dart:397-418,422-459`; pulsanti senza stato di attesa in `media_detail_sheet.dart:142-186,200-263`.
- **Difetto**: se film o serie non sono in catalogo, `isWatched` viene controllato prima di `await addToCatalogue`.
- **Scenario**: un secondo tap passa il controllo e aggiunge un secondo `WatchRecord` a `_watchHistory`. Su disco la chiave coincide, quindi il tempo totale risulta raddoppiato fino al riavvio.
- **Soluzione**: ricontrollare dopo l'`await` oppure inserire in memoria prima di persistere; disabilitare il pulsante durante l'operazione.

#### M10. `pubspec.lock` non versionato

- **Dove**: `.gitignore:3` (`*.lock`).
- **Difetto**: il lock dell'app è escluso dal repository.
- **Effetto**: le build di release in CI risolvono versioni diverse a ogni esecuzione (`intl: any`, range con caret).
- **Soluzione**: versionare il lock dell'app.

#### M11. Immagini senza cache su disco e sovradimensionate

- **Dove**: `lib/core/constants/api_constants.dart:18` (default `w500`); `lib/presentation/widgets/media_card.dart:80-86`; `media_detail_sheet.dart:398-403,681-686`.
- **Difetto**: `Image.network` senza `cacheWidth`. Solo il tile in Home imposta `cacheWidth`.
- **Effetto**: miniature da 72-100 dp scaricano e decodificano poster 500×750 (circa 1,5 MB di RAM l'una); a ogni avvio si riscarica tutto.
- **Soluzione**: `cached_network_image`, dimensioni TMDB adeguate (`w154`/`w185` per le liste), `cacheWidth` ovunque.

### Basso

- **B1. `_withDeferredFlush`** (`app_services.dart:813-825`): con due operazioni sovrapposte, se la prima finisce per prima `_deferFlush` resta `true` e i flush espliciti si fermano. Impatto ridotto: Hive scrive comunque e il lifecycle forza il flush. Soluzione: contatore di profondità.
- **B2. `_dedupe`** (`tmdb_service.dart:451-467`): se la fetch fallisce e nessun altro attende, `completeError` genera un errore asincrono non gestito, che finisce in `PlatformDispatcher.onError` a ogni richiesta fallita. Soluzione: salvare direttamente la future della fetch, oppure chiamare `completer.future.ignore()`.
- **B3. `setState` dopo `dispose`** (`media_detail_sheet.dart:79→113, 228-229, 307-310`): manca il controllo `mounted` dopo gli `await`. Soluzione: aggiungerlo.
- **B4. Runtime 0 ignora il fallback** (`lib/data/models/episode_model.dart:46-47,118`): `runtimeMinutes ?? fallback` non scatta se TMDB restituisce 0 e l'episodio resta non aggiungibile. La logica è verificata; che TMDB invii 0 è un sospetto. Soluzione: trattare `<= 0` come assente.
- **B5. Permesso notifiche chiesto dal background** (`lib/core/background/background_bootstrap.dart:9` → `lib/core/notifications/notification_service.dart:56-61,93-95`): la richiesta parte senza Activity. L'effetto concreto è un sospetto (eccezione non gestita). Soluzione: parametro per saltare la richiesta.
- **B6. "Not now" è un vicolo cieco** (`lib/core/notifications/notification_permission_preprompt.dart:13-15,44`): il pre-prompt non torna più e in Impostazioni non c'è una voce per le notifiche. Soluzione: aggiungere quella voce o riproporre il pre-prompt.
- **B7. Notifiche anche per arretrati** (`lib/core/notifications/episode_notification_policy.dart:17-27`): diventa notificabile ogni alert aggiungibile, anche di serie vecchie. Il commento in `episode_check_service.dart:30-32` dice "aired today", ma i test confermano il comportamento attuale. Soluzione: decidere quale dei due è voluto e allineare l'altro.
- **B8. Nessuna UI di errore all'avvio** (`lib/main.dart:29-33`): se `initializeServices` lancia, l'app resta sullo splash. Soluzione: schermata di errore con possibilità di riprovare.
- **B9. Tema scuro e accessibilità**: `Colors.grey[700]` e rossi fissi in `lib/presentation/screens/settings/settings_screen.dart:63-69,147,210` (contrasto insufficiente su scuro); `IconButton` segnalibro senza tooltip (`media_card.dart:177-184`); font fissi 10-11 px e altezze fisse (carosello cast 198, header 56), con probabile overflow a testo ingrandito (sospetto, non provato). Soluzione: colori dal tema, tooltip, dimensioni non fisse.
- **B10. Back Android**: nessun `PopScope` in `lib/presentation/navigation/main_navigator.dart`; dai tab secondari il back chiude l'app. Soluzione: `PopScope` che riporta al primo tab.
- **B11. Errore fuorviante** (`lib/core/network/dio_client.dart:215-219`): il `catch (_)` trasforma anche gli errori di cast in "nessuna connessione". Il ramo 429 e non-200 alle righe 179-197 è irraggiungibile con il `validateStatus` di default. Soluzione: distinguere i tipi di errore e rendere raggiungibile o rimuovere quel ramo.
- **B12. Codice e configurazione morti**, da rimuovere o correggere: `main_navigator.dart:65-79,106-150`; `AppRouter.routes`; `CacheManager.getStatistics`; `MediaType`; `AppApiKey.setDevKey/setProdKey`; `DioClient.reset/setBaseUrl/headers`; costanti hex in `lib/core/theme/app_theme.dart:205-208`; `.analysis_options.yaml` (con il punto iniziale: ignorato dall'analyzer, regole strict mai applicate); `.idea/workspace.xml` versionato; versione duplicata in `settings_screen.dart:20`; permesso `RECEIVE_BOOT_COMPLETED` superfluo.

## 3. Miglioramenti consigliati

In ordine di priorità.

1. **CI di qualità**: analyze + test su PR e develop; attivare le regole strict oggi nel file ignorato.
2. **Spezzare `AppServices`**: `CatalogueRepository`, `WatchHistoryRepository`, `EpisodeAlertsService`, con stato osservabile (`ChangeNotifier`/`ValueNotifier` per catalogo e cronologia) al posto dei `setState(() {})` e dei callback `onWatchTimeChanged`. Migrazione incrementale, senza introdurre un framework.
3. **Cache TMDB persistente con TTL** (dettagli leggeri e stagioni): abilita l'uso offline e riduce il costo del background. Va rispettato il limite di 6 mesi già previsto.
4. **Rete**: `CancelToken` per ricerca e chiusura scheda; retry con backoff su timeout ed errori di connessione (oggi solo su 429); risultato tipizzato `sealed` al posto di `ApiResult`, che ha `error` valorizzato anche in caso di successo.
5. **Dipendenze**: hive 2.2.3 non è più mantenuto (valutare hive_ce insieme ad A2); flutter_lints 3.0.2 e share_plus 10.1.4 sono indietro di major. Font Roboto in bundle al posto del download a runtime di google_fonts (già dichiarato nella privacy).
6. **UX**: azione rapida "segna visto" sui tile Continue Watching; skeleton al posto degli spinner; stato di attesa sui pulsanti; lingua e regione TMDB dal locale (oggi `en-US` e `US` fissi).
7. **Test mancanti**: `TmdbService` e `DioClient` (cache, dedupe, 429: avrebbero intercettato M2 e B2); collisione ID film/serie; widget test delle schermate; migrazione e restore con dati corrotti.
8. **Crash reporting**: oggi `PlatformDispatcher.onError` logga e inghiotte tutto.

## 4. Non verificato

- **Comportamento su dispositivo reale**: esecuzione di Workmanager/BGTask (tempi iOS, frequenza effettiva), notifiche, permessi, overflow a testo ingrandito, scatti reali (M3 e M11 sono stime da lettura).
- **Corruzione Hive multi-isolate (A2)**: non riprodotta. L'effetto "alert non visibili al resume" è dedotto dal funzionamento dei box non lazy.
- **Dati TMDB**: coppia di titoli con ID 1402 (A1) e `runtime: 0` sugli episodi (B4). Nessuna chiamata API effettuata.
- **Build e versioni**: build Android/iOS e `flutter pub outdated` non eseguiti; le versioni vengono dal `pubspec.lock` locale.
- **File fuori perimetro**: cartelle `web/`, `windows/`, `macos/`, `linux/`, `site/` e `docs/` viste solo marginalmente; i due file l10n generati non sono stati revisionati.
- **Dimensione reale dei payload TMDB e consumo dati del background**: stime.
