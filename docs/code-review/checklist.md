# Checklist code review iz-show-time

- **Ultimo aggiornamento**: 2026-11-15
- **Branch**: `code-review`
- **Dettaglio dei rilievi** (difetto, scenario, soluzione): [2026-11-13-code-review.md](2026-11-13-code-review.md)
- **Legenda**: `- [x]` fatto, `- [ ]` da fare, `- [ ]` + "parziale" fatto solo in parte.

I numeri di riga del report si riferiscono al commit `009503b`: nei file modificati dopo possono essere spostati.

## Stato in breve

- **Rilievi (27)**: 27 fatti, 0 parziali, 0 da fare. Per A4 restano le azioni manuali dello sviluppatore.
- **Miglioramenti consigliati (8)**: 7 fatti, 0 parziali, 0 da fare, 1 non fatto per decisione (il numero 8).
- **Verifiche automatiche al 2026-11-15**:
  - `flutter analyze --no-pub`: nessuna segnalazione, con le regole strict attive.
  - `flutter test --no-pub`: 187 passati, 0 falliti.
  - `flutter build apk --debug`: riuscito.

## Prossimi passi consigliati

1. **A4**: azioni manuali dello sviluppatore, cioè keystore di upload, `android/key.properties` e secret del repository (vedi le caselle aperte sotto A4).
2. **Prova su dispositivo reale** Android e iOS di tutte le voci di "Verifiche ancora da fare".
3. **Privacy policy**: aggiornare `site/privacy.html`, che dichiara ancora il download dei font da Google Fonts. L'app non lo fa più.
4. **Primo run su GitHub** dei workflow CI e Android Release.

## Alto

- [x] **A1** Film e serie condividono la stessa chiave id. Commit `fa05409`.
  - Fatto: chiave composta film/serie (`mediaKeyOf`); schema storage v3 con migrazione delle chiavi del catalogo; backup versione 2 (i backup v1 si importano e vengono convertiti).
  - Limite noto: le voci sovrascritte in passato non sono recuperabili.
- [x] **A2** Hive aperto da due isolate sugli stessi file. Commit `57f262b`.
  - Fatto: il background legge uno snapshot in sola lettura (`HiveUserDataStore.readSnapshot()`) e scrive nel box dedicato `episode_check_outbox`; l'app importa il risultato all'avvio e al ritorno in primo piano (`AppServices.importBackgroundCheckResult()`).
  - Da verificare su dispositivo reale con due isolate (vedi "Verifiche ancora da fare").
- [x] **A3** Controllo nuovi episodi troppo costoso. Commit `40cfd9d`, `ad7f2cf`.
  - Fatto (`40cfd9d`): chiamata leggera `TmdbService.getTvShowSummary`; salto delle richieste di stagione quando non è uscito nulla; 4 serie in parallelo.
  - Fatto (`ad7f2cf`): il controllo in background salva nel box `episode_check_outbox` dopo ogni blocco di 8 serie (`AppConstants.episodeCheckBlockSize`) e aggiorna la notifica di sistema a ogni blocco; le serie non raggiunte mantengono l'avviso precedente; l'esecuzione successiva riparte dalla serie dopo l'ultima controllata (`resumeAfterShowId`), così non restano sempre escluse le stesse.
  - Da verificare su dispositivo: tempi reali dei task iOS (vedi "Verifiche ancora da fare").
- [x] **A4** Configurazione release Android non pubblicabile. Fatto per la parte di codice, commit `e5aca46`, `4a6619a`, `2c8e484`.
  - Fatto (`e5aca46`): firma release da `android/key.properties`, con ripiego sulla chiave debug e avviso.
  - Fatto (`4a6619a`): `applicationId` e `namespace` sono `com.izshowtime.tracker` e `MainActivity.kt` è nel nuovo package. L'app è un'installazione diversa da quelle `com.example.iz_show_time_tracker`.
  - Fatto (`2c8e484`): workflow `.github/workflows/android-release.yml`, che sui tag `v*` e a mano costruisce un App Bundle firmato e lo allega alla run. L'upload su Google Play resta manuale.
  - Azioni manuali dello sviluppatore:
    - [ ] creare il keystore di upload;
    - [ ] creare `android/key.properties` in locale, con le chiavi `storeFile`, `storePassword`, `keyAlias`, `keyPassword`;
    - [ ] aggiungere al repository i secret `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, oltre a `TMDB_API_KEY` (già usato dal workflow iOS).

## Medio

- [x] **M1** Suite di test rossa su develop. Commit `7d8aa5d`.
  - Fatto: test aggiornato al fallback sulla media dei runtime, più un caso senza runtime risolvibile. La suite è verde.
- [x] **M2** `forceRefresh` del trending non salta la cache. Commit `f23e292`.
- [x] **M3** La cache serializza e deserializza JSON a ogni accesso, sul thread UI. Commit `ca95945`.
  - Fatto: la cache tiene gli oggetti senza ricodifica JSON, con TTL e limite LRU di 300 voci; il sync dello stato di messa in onda del catalogo è limitato a una volta ogni 15 minuti.
  - Non fatto: indice dei titoli per la ricerca locale (ora non decodifica più, quindi è meno urgente).
- [x] **M4** `NetworkFeedback.runSilent` silenzia anche gli errori dell'utente. Commit `11a096a`.
  - Fatto: flag "silent" legato alla Zone.
- [x] **M5** Race tra refresh di serie diverse. Commit `247f8e2`.
  - Fatto: il refresh per singola serie sostituisce solo la voce di quella serie negli alert correnti.
- [x] **M6** Home offline nasconde Continue Watching. Commit `78ce5e8`.
  - Fatto: errore confinato alla sezione trending.
  - Non verificato a schermo.
- [x] **M7** Scheda serie: tutte le stagioni scaricate all'apertura e un errore le azzera tutte. Commit `8b1963f`, `7fbe44b`.
  - Fatto (`8b1963f`): una stagione che fallisce diventa un segnaposto vuoto; l'errore è riportato solo se falliscono tutte.
  - Fatto (`7fbe44b`): le stagioni sono elencate dal payload della serie (numerazione reale, speciali inclusi) e ognuna si carica all'espansione; una stagione fallita mostra "Could not load episodes. Tap to retry." e si ricarica al tocco. Tre widget test lo verificano.
  - Non verificato a schermo.
- [x] **M8** Restore del backup non atomico. Commit `23725f2`.
  - Fatto: le voci del backup sono validate prima di svuotare i box; il contenuto precedente viene ripristinato se l'import fallisce.
- [x] **M9** Doppio tap crea record duplicati in memoria. Commit `952552e`, `7fbe44b`.
  - Fatto (`952552e`): ricontrollo dopo l'await; un doppio tap registra una sola volta.
  - Fatto (`7fbe44b`): i pulsanti della scheda sono disabilitati mentre l'operazione è in corso.
- [x] **M10** `pubspec.lock` non versionato. Commit `93c249d`.
- [x] **M11** Immagini senza cache su disco e sovradimensionate. Commit `94b368b`, `1f34085`, `1a18f0e`.
  - Fatto (`94b368b`): miniature e poster della scheda richiedono la dimensione w342 e passano `cacheWidth`.
  - Fatto (`1f34085`, `1a18f0e`): immagini su disco con `cached_network_image` tramite il widget `AppNetworkImage`; la cache viene svuotata con la purga TMDB.
  - Nota: `flutter_cache_manager` è diventata dipendenza diretta per poter svuotare la cache.
  - Non verificato a schermo.

## Basso

- [x] **B1** `_withDeferredFlush` blocca i flush con operazioni sovrapposte. Commit `952552e`, insieme a M9.
  - Fatto: contatore di profondità al posto del flag.
- [x] **B2** `_dedupe` genera un errore asincrono non gestito. Commit `32972c3`.
- [x] **B3** `setState` dopo `dispose`. Commit `dbbc443`.
- [x] **B4** Runtime 0 ignora il fallback. Commit `2fd696b`.
- [x] **B5** Permesso notifiche chiesto dal background. Chiuso insieme ad A2 (commit `57f262b`): il background non chiede più il permesso notifiche.
- [x] **B6** "Not now" è un vicolo cieco. Commit `54604f2`.
  - Fatto: voce "Notifications" nelle Impostazioni che mostra lo stato e chiede il permesso; se il sistema lo blocca, rimanda alle impostazioni del dispositivo.
  - Non verificato a schermo.
- [x] **B7** Notifiche anche per arretrati. Commit `d01e3ef`.
  - Fatto: notifica di sistema solo per episodi usciti negli ultimi 7 giorni (`AppConstants.notificationRecentAirDays`); gli episodi senza data non notificano.
- [x] **B8** Nessuna UI di errore all'avvio. Commit `a650826`.
  - Fatto: schermata di errore con "Retry" se l'avvio fallisce.
  - Non verificata a schermo.
- [x] **B9** Tema scuro e accessibilità. Commit `c3d7044`, `dcd3926`.
  - Fatto (`c3d7044`): colori dal tema nelle impostazioni; tooltip sul pulsante segnalibro.
  - Fatto (`dcd3926`): i font fissi usano gli stili del tema; l'altezza del carosello cast cresce con la dimensione del testo.
  - Non modificato: l'header resta a 56 px, perché contiene solo immagini e una riga di testo.
  - Non verificato a schermo.
- [x] **B10** Back Android chiude l'app dai tab secondari. Commit `16bb6ea`.
  - Fatto: il tasto indietro dai tab secondari torna a Home.
  - Non verificato su dispositivo.
- [x] **B11** Errore fuorviante "nessuna connessione". Commit `df2aa4b`.
- [x] **B12** Codice e configurazione morti. Commit `a215903`, `a3c3ed7`.
  - Fatto (`a215903`): rimossi helper inutilizzati del navigator, tabella `AppRouter.routes`, `MediaType`, `AppApiKey.setDevKey/setProdKey`, `DioClient.reset/setBaseUrl/headers`, `CacheManager.getStatistics`, costanti hex del tema, helper `_mediaSeenKey` duplicati; cancellato `.analysis_options.yaml`; `.idea/workspace.xml` non più tracciato.
  - Fatto (`a3c3ed7`): versione letta da `package_info_plus`; rimosso il permesso `RECEIVE_BOOT_COMPLETED` a livello app (WorkManager unisce il proprio).

## Miglioramenti consigliati

Sezione 3 del report, stesso ordine di priorità.

- [x] **1** CI di qualità: analyze e test, regole strict. Commit `c70ba26`, `f14c935`.
  - Fatto (`c70ba26`): workflow `.github/workflows/ci.yml` con analyze e test su push a `main`/`develop` e sulle pull request.
  - Fatto (`f14c935`): attive `strict-casts`, `strict-inference`, `strict-raw-types` e le regole di lint del vecchio file.
  - Non fatto: `require_trailing_commas` è esclusa, perché in conflitto con il formattatore Dart.
- [x] **2** Spezzare `AppServices`. Commit `fa8e8d2`, `9578825`, `8fb1bed`.
  - Fatto: estrazione graduale di `WatchHistoryIndex`, `CatalogueIndex` ed `EpisodeAlertsService` in `lib/core/services`; `AppServices` resta facciata con API invariate (da 1031 a 747 righe).
  - Non fatto, per scelta: stato osservabile nelle schermate.
- [x] **3** Cache TMDB persistente con TTL. Commit `1f51f0c`.
  - Fatto: `TmdbDiskCache`, box Hive `tmdb_cache` per dettagli e stagioni; una copia scaduta viene servita se la rete non c'è; limite di 150 voci; svuotata con la purga TMDB.
  - Limite: la usa solo l'isolate dell'interfaccia, quindi il controllo in background non ne beneficia.
- [x] **4** Rete: `CancelToken`, retry con backoff, risultato tipizzato. Commit `75e6e23`.
  - Fatto: `ApiResult` sealed; due nuovi tentativi con attesa breve su timeout ed errori di connessione; una nuova ricerca annulla la richiesta della precedente.
  - Non fatto, per scelta: annullamento alla chiusura della scheda (la richiesta completa e resta in cache).
- [x] **5** Dipendenze: hive, flutter_lints, share_plus, font in bundle. Commit `6b4577d`, `a01a474`, `e9fefac`.
  - Fatto: `hive` → `hive_ce`; `flutter_lints` 6, `share_plus` 13, `package_info_plus` 10 (richiesta da `share_plus`); font Roboto nel bundle, `google_fonts` rimosso.
- [x] **6** UX: azione rapida "segna visto", skeleton, stati di attesa, lingua e regione dal locale. Commit `2f603c4`, `04e249e`, `d72cbc2`, `7fbe44b`.
  - Fatto: "segna visto" dal riquadro di Continue Watching; skeleton in Home, ricerca e scheda; lingua e regione TMDB dal dispositivo (`TmdbLocale`); pulsanti in attesa.
  - Non verificato a schermo.
- [x] **7** Test mancanti. Commit `c1e300c`, più i test aggiunti nei singoli commit.
  - Fatto in precedenza: test per collisione di id film/serie, migrazione v3, restore con dati non validi, doppio tap, gara tra refresh, cache, `NetworkFeedback`, runtime 0, `getTvSeasons`.
  - Fatto ora: test di `DioClient` (429, errori, retry, annullamento), widget test della scheda, test di cache su disco, policy notifiche, controllo in background.
  - Totale: da 130 a 187 test.
  - Restano utili: widget test delle altre schermate.
- [ ] **8** Crash reporting. **Non fatto per decisione**: nessun servizio di crash reporting per ora.

## Verifiche ancora da fare

- [ ] Controllo in background su dispositivo reale Android e iOS: due isolate, tempi dei task iOS, notifiche.
- [ ] Migrazione dello schema v3 su un'installazione reale con dati esistenti.
- [ ] Migrazione a `hive_ce` con i dati di un'installazione esistente. `hive_ce` può scrivere un avviso nel log quando il controllo in background apre i box in sola lettura.
- [ ] Build di release Android firmata con un keystore vero.
- [ ] Tutte le voci della sezione "Non verificato" del report, ancora valide.
- [ ] Modifiche d'interfaccia di M6, B8, B9, B10 e M11 non verificate a schermo.
- [ ] Interfaccia nuova non verificata a schermo: stagioni a espansione, skeleton, "segna visto" rapido, voce Notifiche, immagini con cache su disco, font Roboto dal bundle, condivisione del backup con `share_plus` 13.
- [ ] Testi TMDB nella lingua del dispositivo: titoli e trame non tradotti possono arrivare vuoti o in lingua originale.
- [ ] I titoli già in catalogo restano nella lingua in cui sono stati aggiunti.
- [ ] Primo run del workflow CI su GitHub.
- [ ] Primo run del workflow Android Release su GitHub.

## Decisioni prese (2026-11-15)

Scelte dello sviluppatore per sbloccare le voci aperte.

- **M11**: cache immagini su disco con `cached_network_image`.
- **B12**: versione letta dal pacchetto con `package_info_plus`.
- **B7**: notifica di sistema solo per episodi usciti di recente (7 giorni); gli arretrati restano in Continue Watching senza notifica.
- **B6**: voce "Notifiche" nelle Impostazioni che mostra lo stato e chiede il permesso.
- **Miglioramento 2**: estrazione graduale di `AppServices` in tre classi (catalogo, cronologia, avvisi), con `AppServices` come facciata e API invariate.
- **Miglioramento 3**: cache TMDB persistente in un box Hive dedicato, usata solo dall'isolate dell'interfaccia.
- **Miglioramento 5**: `hive` → `hive_ce`; `flutter_lints` e `share_plus` all'ultima major; font Roboto nel bundle.
- **Miglioramento 6**: "segna visto" rapido in Continue Watching; pulsanti disabilitati durante l'operazione; skeleton di caricamento; lingua e regione TMDB dal dispositivo.
- **Miglioramento 8**: nessun servizio di crash reporting per ora.
