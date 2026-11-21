# Notifiche nuovi episodi — Fase 1 (bug) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chiudere tre bug del flusso notifiche nuovi episodi: alert persi su errore TMDB transitorio (con notifica duplicata), suoni multipli nello stesso run background, notifica stantia nel vassoio.

**Architecture:** Tre interventi indipendenti. (1) `NewEpisodeChecker` conserva l'alert precedente di uno show quando TMDB fallisce in modo transitorio. (2) `EpisodeCheckService.checkAndStore` passa al notifier un flag `silent`: solo il primo avviso del run suona. (3) `NotificationService` espone la cancellazione della notifica; `AppLifecycleCoordinator` e il bootstrap post-frame la invocano quando l'app torna in primo piano.

**Tech Stack:** Flutter / Dart 3, flutter_local_notifications ^22.3.0, workmanager, hive_ce, flutter_test con fake scritti a mano.

**Spec:** analisi in conversazione del 2026-11-21, punti A, B, C, J (sintesi sotto).

- **A** — [new_episode_checker.dart:78](../../../lib/core/notifications/new_episode_checker.dart) restituisce `null` su `ApiException`; il merge (righe 104-109) tiene solo gli alert degli show fuori dal blocco. Effetto: riga Continue Watching persa; in background l'id esce da `notified` ([episode_check_service.dart:481](../../../lib/core/notifications/episode_check_service.dart)) quando nello stesso run c'è un altro episodio idoneo → notifica duplicata al run successivo.
- **B** — `notify()` è chiamato dopo ogni blocco ([episode_check_service.dart:476](../../../lib/core/notifications/episode_check_service.dart)); Android ri-allerta a ogni `show()` con lo stesso id.
- **C** — aprendo l'app dal launcher la notifica id 1 resta nel vassoio col conteggio vecchio, mentre il conteggio interno si azzera (`appLeftForegroundAt`).
- **J** — nessun test copre i casi A e B.

## Global Constraints

- Nessuna nuova dipendenza in `pubspec.yaml`.
- Nessun cambio a schema Hive, `StorageConstants.storageSchemaVersion`, formato outbox o backup.
- Nessuna nuova stringa l10n.
- Test: fake scritti a mano, nessun mock/mocktail. Fake condiviso: `test/support/fake_user_data_store.dart`.
- `flutter analyze` resta a `No issues found!`; `flutter test` tutto verde.
- Commenti nel codice solo dove la logica non è ovvia, in inglese come il resto del codice.
- Messaggi di commit in inglese, chiusi da `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Branch unico per tutte le fasi: `fix/new-episode-notifications`, da `develop`.
- Nessun commit autonomo: a fine task mostrare le modifiche e chiedere all'utente se committare, prima di passare al task successivo. I passi "Commit" indicano file e messaggio proposti.

## Review Focus

1. Show rimosso da TMDB (`ApiErrorType.notFound`): l'alert deve sparire, non restare congelato → test in Task 1.
2. Alert conservato il cui episodio l'utente ha già registrato: non deve tornare in Continue Watching → test in Task 1.
3. Run successivo a uno con avvisi: il primo avviso del nuovo run deve suonare di nuovo (il flag è per-run, non persistito) → test in Task 2.
4. Resume prima che `NotificationService` sia inizializzato (cold start): nessuna eccezione, nessuna chiamata al plugin → guard `_initialized` in Task 3.
5. Stati `inactive` / `hidden` / `paused` (es. tendina notifiche abbassata): la notifica NON va cancellata → test in Task 3.

---

### Task 1: Conservare l'alert su errore TMDB transitorio (A + J)

**Files:**
- Modify: `lib/core/notifications/new_episode_checker.dart:69-82`
- Test: `test/notifications/new_episode_checker_test.dart`
- Test: `test/notifications/episode_check_service_test.dart`

**Interfaces:**
- Consumes: `ApiException`, `ApiErrorType` da `lib/core/network/api_error.dart`.
- Produces: nessuna API nuova. Comportamento: su `ApiException` con tipo ≠ `notFound`, `checkShows` restituisce in `allAlerts` l'alert precedente dello show (da `existingAlerts` o dallo store), purché il suo `episodeId` non sia in `watchHistory`. Non compare in `newlyDetected`.

- [ ] **Step 1: Aggiungere lo stub che fallisce e i test del checker**

In `new_episode_checker_test.dart` aggiungere:

```dart
/// Throws [errorType] for every request, like TMDB failing for this show.
class FailingTmdbService extends TmdbService {
  FailingTmdbService(this.errorType) : super(cacheManager: null);
  final ApiErrorType errorType;

  @override
  Future<TvShowSummary?> getTvShowSummary(int tvId, {bool forceRefresh = false}) async =>
      throw ApiException(errorType, 'stub');

  @override
  Future<List<EpisodeModel>> getSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    bool forceRefresh = false,
  }) async =>
      throw ApiException(errorType, 'stub');
}
```

Fixture comune: `show = TvShow(id: 42, title: 'Sample Show')`; `watchHistory` con l'episodio `id: 100` (S1E2); `prior = NewEpisodeAlert(showId: 42, showTitle: 'Sample Show', episodeId: 101, seasonNumber: 1, episodeNumber: 3, episodeName: 'Next', airDate: DateTime(2026, 1, 8), runtimeMinutes: 45, detectedAt: DateTime(2026, 1, 8))`.

Test, in un `group('on TMDB failure', ...)`, tutti con `persistAlerts: false` e `existingAlerts: [prior]`:

- `keeps the previous alert on a transient error` — `FailingTmdbService(ApiErrorType.timeout)`, `mergeWithExisting: false` → `result.allAlerts.map((a) => a.episodeId)` == `[101]`; `result.newlyDetected` isEmpty.
- `keeps the previous alert when merging a block` — come sopra con `mergeWithExisting: true` → `[101]`.
- `drops the alert when TMDB no longer has the show` — `ApiErrorType.notFound` → `allAlerts` isEmpty.
- `drops a kept alert whose episode is already registered` — `timeout`, `watchHistory` include anche un `WatchRecord` con `episodeId: 101` (S1E3) → `allAlerts` isEmpty.

- [ ] **Step 2: Aggiungere il test di non-duplicazione in background**

In `episode_check_service_test.dart`, estendere `_TwoEpisodeStubTmdbService` con `this.apiFailingShowIds = const {}` (`Set<int>`): in `getSeasonEpisodes`, per quegli show, `throw const ApiException(ApiErrorType.timeout, 'timeout')`.

Test `a transient TMDB failure does not notify the same episode again`, blocco unico (default):
1. Run 1, stub normale → 5 episodi notificati (`12, 22, 32, 42, 52`).
2. Run 2, `apiFailingShowIds: {1}`, `episodeCount: {2: 3}` → atteso: un avviso (episodio `23`); `outbox.notifiedEpisodeIds` contiene ancora `12`; `storedEpisodeIds()` contiene `12`.
3. Run 3, stub normale con `episodeCount: {2: 3}` → nessun avviso.

Le asserzioni sugli avvisi usano la forma del notifier in vigore al momento dell'esecuzione (se il Task 2 è già fatto, record `(count:, silent:)`).

- [ ] **Step 3: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/new_episode_checker_test.dart test/notifications/episode_check_service_test.dart`
Expected: FAIL su `keeps the previous alert on a transient error`, `keeps the previous alert when merging a block` e sul run 3 del test background (avviso duplicato). `drops ...` già verdi.

- [ ] **Step 4: Implementare in `new_episode_checker.dart`**

Nel `checkShow` locale: `on ApiException catch (error)` → `return _alertKeptOnFailure(error, priorByShowId[show.id], watchHistory);`

Nuovo metodo `static NewEpisodeAlert? _alertKeptOnFailure(ApiException error, NewEpisodeAlert? prior, List<WatchRecord> watchHistory)`: `null` se `error.type == ApiErrorType.notFound`, se `prior == null`, o se un record non-film di `watchHistory` ha `episodeId == prior.episodeId`; altrimenti `prior`. Commento di una riga sul perché (un errore transitorio non è un verdetto: perdere l'alert fa sparire la riga e ri-notificare l'episodio).

Aggiornare il commento di riga 79 di conseguenza.

- [ ] **Step 5: Eseguire i test e verificare che passino**

Run: `flutter test test/notifications/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/notifications/new_episode_checker.dart test/notifications/new_episode_checker_test.dart test/notifications/episode_check_service_test.dart
git commit -m "Keep a show's alert when TMDB fails transiently"
```

---

### Task 2: Un solo avviso sonoro per run background (B + J)

**Files:**
- Modify: `lib/core/notifications/episode_check_service.dart` (typedef, `runNativeBackgroundCheck`, `checkAndStore`)
- Modify: `lib/core/notifications/notification_service.dart:149-185`
- Test: `test/notifications/episode_check_service_test.dart`

**Interfaces:**
- Produces:
  - `typedef NewEpisodesNotifier = Future<void> Function(int count, {required bool silent});` in `episode_check_service.dart`.
  - `checkAndStore({..., required NewEpisodesNotifier notify, ...})`.
  - `NotificationService.showNewEpisodesNotification({required int count, bool silent = false})`.

- [ ] **Step 1: Adattare i test esistenti e scrivere quello nuovo**

In `episode_check_service_test.dart` i notifier registrano record:

```dart
final notifications = <({int count, bool silent})>[];
Future<void> notify(int count, {required bool silent}) async =>
    notifications.add((count: count, silent: silent));
```

Aggiornare le aspettative esistenti:
- `an interrupted run ...`: run 1 `[(count: 2, silent: false)]`; run 2 `[(count: 4, silent: false), (count: 5, silent: true)]`.
- `counts every aired episode ...`: `[(count: 7, silent: false)]`.
- `restarts the count ...`: `[(count: 5, silent: false)]` poi `[(count: 1, silent: false)]`.
- `does not notify while the app is in foreground`: resta `isEmpty`.
- Test del Task 1 (se già presente): run 2 `[(count: 6, silent: false)]`.

Nuovo test `alerts once per run and updates silently afterwards`: `blockSize: 2`, stub normale, 5 show → `[(count: 2, silent: false), (count: 4, silent: true), (count: 5, silent: true)]`.

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/episode_check_service_test.dart`
Expected: FAIL di compilazione (il parametro `notify` non accetta `silent`).

- [ ] **Step 3: Implementare**

- `checkAndStore`: variabile locale `var alertedThisRun = false;`; chiamata `await notify(notifiedAt.length, silent: alertedThisRun);` seguita da `alertedThisRun = true;`. Commento: il primo avviso del run suona, gli aggiornamenti dello stesso run sostituiscono il testo in silenzio.
- `runNativeBackgroundCheck`: `notify: (count, {required silent}) => NotificationService().showNewEpisodesNotification(count: count, silent: silent)`.
- `showNewEpisodesNotification`: `AndroidNotificationDetails(..., silent: silent)`; `DarwinNotificationDetails(presentSound: !silent)` per iOS e macOS (non più `const`).

- [ ] **Step 4: Eseguire i test e verificare che passino**

Run: `flutter test test/notifications/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/notifications/episode_check_service.dart lib/core/notifications/notification_service.dart test/notifications/episode_check_service_test.dart
git commit -m "Sound the new episodes notification once per background run"
```

---

### Task 3: Togliere la notifica stantia all'apertura dell'app (C)

**Files:**
- Modify: `lib/core/notifications/notification_service.dart`
- Modify: `lib/core/notifications/app_lifecycle_coordinator.dart`
- Modify: `lib/main.dart:71-83`
- Create: `test/notifications/app_lifecycle_coordinator_test.dart`

**Interfaces:**
- Produces:
  - `Future<void> NotificationService.cancelNewEpisodesNotification()` — no-op se `!_initialized`; chiama `_plugin.cancel(...)` con `_newEpisodesNotificationId` (stessa convenzione di parametri nominati di `show` nella v22); errori catturati con `debugPrint`, come in `showNewEpisodesNotification`.
  - `AppLifecycleCoordinator({required AppServices appServices, Future<void> Function()? clearNewEpisodesNotification})` — default `NotificationService().cancelNewEpisodesNotification`.

- [ ] **Step 1: Scrivere il test del coordinator**

`test/notifications/app_lifecycle_coordinator_test.dart`:
- `TestWidgetsFlutterBinding.ensureInitialized()`; `AppServices().userDataStore = FakeUserDataStore()`.
- Coordinator con `clearNewEpisodesNotification` che incrementa un contatore.
- `clears the new episodes notification on resume` — `didChangeAppLifecycleState(AppLifecycleState.resumed)` → contatore `1`.
- `keeps the notification in other states` — `inactive`, `hidden`, `paused` → contatore `0`.

Chiamare `didChangeAppLifecycleState` direttamente (senza `attach()`).

- [ ] **Step 2: Eseguire il test e verificare che fallisca**

Run: `flutter test test/notifications/app_lifecycle_coordinator_test.dart`
Expected: FAIL di compilazione (parametro `clearNewEpisodesNotification` inesistente).

- [ ] **Step 3: Implementare**

- `NotificationService.cancelNewEpisodesNotification()` come da Interfaces.
- `AppLifecycleCoordinator`: campo privato per il callback; in `didChangeAppLifecycleState`, ramo `resumed`, `unawaited(_clearNewEpisodesNotification());` accanto all'import dell'outbox.
- `main.dart` `_bootstrapAfterFirstFrame`: subito dopo `NotificationService().initialize(...)`, `await NotificationService().cancelNewEpisodesNotification();` — copre il cold start, in cui il primo `resumed` arriva prima dell'inizializzazione e il guard lo salta.

- [ ] **Step 4: Eseguire i test e verificare che passino**

Run: `flutter test test/notifications/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/notifications/notification_service.dart lib/core/notifications/app_lifecycle_coordinator.dart lib/main.dart test/notifications/app_lifecycle_coordinator_test.dart
git commit -m "Clear the new episodes notification when the app is opened"
```

---

### Task 4: Verifica finale

- [ ] **Step 1: Analisi statica**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Suite completa**

Run: `flutter test`
Expected: tutti i test PASS.

- [ ] **Step 3: Verifica manuale su emulatore Android (facoltativa, consigliata)**

Non coperto dai test: suono effettivo di `silent`, `presentSound` su iOS, cancellazione dal vassoio. Su emulatore: forzare il task WorkManager con app in background, verificare un solo suono; riaprire l'app dal launcher, verificare che la notifica sparisca. L'emulatore può essere usato in parallelo dall'utente: verificare prima di segnalare un bug.
