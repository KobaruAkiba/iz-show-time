# Checklist code review iz-show-time

- **Ultimo aggiornamento**: 2026-11-14
- **Branch**: `code-review`
- **Dettaglio dei rilievi** (difetto, scenario, soluzione): [2026-11-13-code-review.md](2026-11-13-code-review.md)
- **Legenda**: `- [x]` fatto, `- [ ]` da fare, `- [ ]` + "parziale" fatto solo in parte.

I numeri di riga del report si riferiscono al commit `009503b`: nei file modificati dopo possono essere spostati.

## Stato in breve

- **Rilievi (27)**: 20 fatti, 5 parziali, 2 da fare.
- **Miglioramenti consigliati (8)**: 0 fatti, 2 parziali, 6 da fare.
- **Verifiche automatiche al 2026-11-14**:
  - `flutter analyze --no-pub`: nessuna segnalazione.
  - `flutter test --no-pub`: 165 passati, 0 falliti.
  - `flutter build apk --debug`: riuscito con il nuovo `applicationId`.

## Prossimi passi consigliati

1. **A4**: azioni manuali dello sviluppatore, cioè keystore di upload, `android/key.properties` e secret del repository (vedi le caselle aperte sotto A4).
2. **Verifica su dispositivo reale** delle modifiche d'interfaccia e del controllo in background (vedi "Verifiche ancora da fare").
3. **M7**: caricare le stagioni all'espansione. Parti da `lib/presentation/widgets/media_detail_sheet.dart`.
4. **M11**: cache su disco delle immagini.
5. **Miglioramento 1**: attivare le regole strict.
6. **Miglioramenti 2 e 3**: spezzare `AppServices`, cache TMDB persistente.

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
- [ ] **M7** Scheda serie: tutte le stagioni scaricate all'apertura e un errore le azzera tutte. **Parziale**, commit `8b1963f`.
  - Fatto: una stagione che fallisce diventa un segnaposto vuoto; l'errore è riportato solo se falliscono tutte.
  - Resta, partendo da `lib/presentation/widgets/media_detail_sheet.dart`:
    1. caricare la stagione all'espansione;
    2. leggere `seasons[]` dal dettaglio (numerazione non contigua, speciali);
    3. errore visibile per singola stagione.
- [x] **M8** Restore del backup non atomico. Commit `23725f2`.
  - Fatto: le voci del backup sono validate prima di svuotare i box; il contenuto precedente viene ripristinato se l'import fallisce.
- [ ] **M9** Doppio tap crea record duplicati in memoria. **Parziale**, commit `952552e`.
  - Fatto: ricontrollo dopo l'await; un doppio tap registra una sola volta.
  - Resta: disabilitare i pulsanti durante l'operazione in `lib/presentation/widgets/media_detail_sheet.dart`.
- [x] **M10** `pubspec.lock` non versionato. Commit `93c249d`.
- [ ] **M11** Immagini senza cache su disco e sovradimensionate. **Parziale**, commit `94b368b`.
  - Fatto: miniature e poster della scheda richiedono la dimensione w342 e passano `cacheWidth`.
  - Resta: cache su disco delle immagini (per esempio `cached_network_image`); va svuotata insieme alla purga dei dati TMDB prevista dai termini d'uso (vedi `AppServices.clearCacheData`).

## Basso

- [x] **B1** `_withDeferredFlush` blocca i flush con operazioni sovrapposte. Commit `952552e`, insieme a M9.
  - Fatto: contatore di profondità al posto del flag.
- [x] **B2** `_dedupe` genera un errore asincrono non gestito. Commit `32972c3`.
- [x] **B3** `setState` dopo `dispose`. Commit `dbbc443`.
- [x] **B4** Runtime 0 ignora il fallback. Commit `2fd696b`.
- [x] **B5** Permesso notifiche chiesto dal background. Chiuso insieme ad A2 (commit `57f262b`): il background non chiede più il permesso notifiche.
- [ ] **B6** "Not now" è un vicolo cieco. Parti da `lib/core/notifications/notification_permission_preprompt.dart`.
- [ ] **B7** Notifiche anche per arretrati. Parti da `lib/core/notifications/episode_notification_policy.dart`.
  - Richiede una decisione: notificare anche gli arretrati oppure solo gli episodi usciti oggi.
- [x] **B8** Nessuna UI di errore all'avvio. Commit `a650826`.
  - Fatto: schermata di errore con "Retry" se l'avvio fallisce.
  - Non verificata a schermo.
- [ ] **B9** Tema scuro e accessibilità. **Parziale**, commit `c3d7044`.
  - Fatto: colori dal tema nelle impostazioni; tooltip sul pulsante segnalibro.
  - Resta: font fissi 10-11 px e altezze fisse (carosello cast, header).
- [x] **B10** Back Android chiude l'app dai tab secondari. Commit `16bb6ea`.
  - Fatto: il tasto indietro dai tab secondari torna a Home.
  - Non verificato su dispositivo.
- [x] **B11** Errore fuorviante "nessuna connessione". Commit `df2aa4b`.
- [ ] **B12** Codice e configurazione morti. **Parziale**, commit `a215903`.
  - Fatto: rimossi helper inutilizzati del navigator, tabella `AppRouter.routes`, `MediaType`, `AppApiKey.setDevKey/setProdKey`, `DioClient.reset/setBaseUrl/headers`, `CacheManager.getStatistics`, costanti hex del tema, helper `_mediaSeenKey` duplicati; cancellato `.analysis_options.yaml`; `.idea/workspace.xml` non più tracciato.
  - Resta:
    1. versione duplicata in `lib/presentation/screens/settings/settings_screen.dart` (serve una dipendenza come `package_info_plus`);
    2. permesso `RECEIVE_BOOT_COMPLETED` da valutare.

## Miglioramenti consigliati

Sezione 3 del report, stesso ordine di priorità.

- [ ] **1** CI di qualità: analyze e test, regole strict. **Parziale**, commit `c70ba26`.
  - Fatto: workflow `.github/workflows/ci.yml` con analyze e test su push a `main`/`develop` e sulle pull request.
  - Resta: attivare le regole strict (`strict-casts`, `strict-inference`, `strict-raw-types`, `require_trailing_commas`). Provate in locale: generano 48 segnalazioni da sistemare prima.
- [ ] **2** Spezzare `AppServices`.
- [ ] **3** Cache TMDB persistente con TTL.
- [ ] **4** Rete: `CancelToken`, retry con backoff, risultato tipizzato.
- [ ] **5** Dipendenze: hive, flutter_lints, share_plus, font in bundle.
- [ ] **6** UX: azione rapida "segna visto", skeleton, stati di attesa, lingua e regione dal locale.
- [ ] **7** Test mancanti. **Parziale**.
  - Fatto: test per collisione di id film/serie, migrazione v3, restore con dati non validi, doppio tap, gara tra refresh, cache, `NetworkFeedback`, runtime 0, `getTvSeasons` (da 130 a 165 test).
  - Resta: test di `DioClient` (429, dedupe) e widget test delle schermate.
- [ ] **8** Crash reporting.

## Verifiche ancora da fare

- [ ] Controllo in background su dispositivo reale Android e iOS: due isolate, tempi dei task iOS, notifiche.
- [ ] Migrazione dello schema v3 su un'installazione reale con dati esistenti.
- [ ] Build di release Android firmata con un keystore vero.
- [ ] Tutte le voci della sezione "Non verificato" del report, ancora valide.
- [ ] Modifiche d'interfaccia di M6, B8, B9, B10 e M11 non verificate a schermo.
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
