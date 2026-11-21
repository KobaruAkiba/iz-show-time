# Notifiche nuovi episodi — Fase 2 (robustezza) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendere affidabile il flusso notifiche: non marcare episodi quando la notifica non viene mostrata (I), non bloccare le notifiche per un flag "in primo piano" rimasto vecchio (D), aggiornare Continue Watching al rientro quando l'ultimo controllo è vecchio (F).

**Architecture:** (I) il notifier restituisce `bool` (mostrata sì/no) e `checkAndStore` marca solo se `true`. (D) `saveAppInForeground(true)` salva anche un heartbeat; il coordinator lo rinnova ogni 5 minuti mentre l'app è `resumed`; il background considera l'app aperta solo con heartbeat recente (≤ 15 minuti). (F) al rientro `EpisodeAlertsService` importa l'outbox e, se l'ultimo controllo ha più di 2 ore, lancia il refresh di rete; i refresh completi concorrenti condividono la stessa esecuzione.

**Tech Stack:** Flutter / Dart 3, flutter_local_notifications ^22.3.0, hive_ce, flutter_test con fake scritti a mano.

**Spec:** analisi in conversazione del 2026-11-21, punti D, F, I. Fase 1: `docs/superpowers/plans/2026-11-21-new-episode-notifications-phase1.md`.

- **D** — `attach()` scrive sempre `true` ([app_lifecycle_coordinator.dart](../../../lib/core/notifications/app_lifecycle_coordinator.dart)), così come [main.dart:37](../../../lib/main.dart). Dopo un crash in primo piano il flag resta `true` e il background non notifica più.
- **F** — al rientro si importa solo l'outbox: su iOS il controllo in background è raro e Continue Watching resta vecchio fino al timer di 2 ore.
- **I** — con le notifiche spente gli episodi vengono marcati comunque ([episode_check_service.dart](../../../lib/core/notifications/episode_check_service.dart)): riattivandole non arriva nulla.

## Global Constraints

- Branch: `fix/new-episode-notifications` (già esistente). Non cambiarlo.
- Nessun commit autonomo: a fine task mostrare le modifiche e chiedere all'utente se committare. I passi "Commit" indicano file e messaggio proposti.
- Nessuna nuova dipendenza; nessun bump di `storageSchemaVersion`; formato outbox e backup invariati.
- La nuova chiave heartbeat NON entra in `_backupMetaKeys`, ma va cancellata dove si cancellano `appInForegroundKey` / `appLeftForegroundAtKey`.
- Nessuna nuova stringa l10n.
- Test: fake scritti a mano; fake condiviso `test/support/fake_user_data_store.dart`.
- File in CRLF: preservare i fine riga. `dart format` solo sui file toccati.
- `flutter analyze` a `No issues found!`; `flutter test` tutto verde.
- Commenti in inglese solo dove la logica non è ovvia. Commit in inglese con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. Notifica fallita nel primo blocco e riuscita nel secondo: il secondo avviso deve suonare (non è "già avvisato") e contare anche gli episodi del primo blocco → test in Task 1.
2. Heartbeat assente con flag `true` (dati salvati da versioni precedenti o crash): l'app va considerata chiusa → test in Task 2.
3. App in pausa: il timer heartbeat deve fermarsi, altrimenti il flag non scade mai → test in Task 2.
4. Rientro con ultimo controllo recente: nessuna richiesta di rete → test in Task 3.
5. Rientro mentre il ciclo di avvio sta già aggiornando: una sola esecuzione → test in Task 3.

---

### Task 1: Marcare solo le notifiche mostrate (I)

**Files:**
- Modify: `lib/core/notifications/episode_check_service.dart`
- Modify: `lib/core/notifications/notification_service.dart`
- Test: `test/notifications/episode_check_service_test.dart`

**Interfaces:**
- Produces:
  - `typedef NewEpisodesNotifier = Future<bool> Function(int count, {required bool silent});` — `true` se la notifica è stata mostrata.
  - `Future<bool> NotificationService.showNewEpisodesNotification({required int count, bool silent = false})` — `false` se non inizializzato, `count <= 0`, `!await areNotificationsEnabled()` o eccezione del plugin; `true` dopo `show` riuscito.

- [ ] **Step 1: Adattare i test e scrivere i nuovi**

Tutti i notifier dei test restituiscono `true` dopo aver registrato il record. Nuovi test:

- `does not mark episodes while notifications are off` — notifier che registra e restituisce `false`, stub normale, blocco unico → `notifications == [(count: 5, silent: false)]`; `outbox.notifiedEpisodeIds` vuoto; `outbox.notifiedAt` vuoto. Secondo run con notifier che restituisce `true` → `[(count: 5, silent: false)]` e `outbox.notifiedEpisodeIds == {12, 22, 32, 42, 52}`.
- `alerts with sound after a notification that was not shown` — `blockSize: 2`; notifier che restituisce `false` alla prima chiamata e `true` dopo → `[(count: 2, silent: false), (count: 4, silent: false), (count: 5, silent: true)]`.

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/episode_check_service_test.dart`
Expected: FAIL di compilazione (i notifier restituiscono `bool`, il typedef `void`).

- [ ] **Step 3: Implementare**

In `checkAndStore`: calcolare la mappa candidata `{...notifiedAt, for (final id in eligible) id: now}`; chiamare `notify(candidata.length, silent: alertedThisRun)`; solo se restituisce `true` assegnare `notifiedAt`, impostare `alertedThisRun = true` e aggiornare/potare `notified`. In `showNewEpisodesNotification` applicare le regole di Interfaces.

- [ ] **Step 4: Eseguire i test e verificare che passino**

Run: `flutter test test/notifications/`
Expected: PASS.

- [ ] **Step 5: Commit (su conferma dell'utente)**

File: i tre sopra + questo piano. Messaggio: `Mark episodes as notified only when the notification is shown`.

---

### Task 2: Flag "in primo piano" con scadenza (D)

**Files:**
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/core/constants/storage_constants.dart`
- Modify: `lib/data/repositories/hive_user_data_store.dart` (`UserDataSnapshot`, `readSnapshot`, `saveAppInForeground`, nuovo loader, cancellazione chiavi)
- Modify: `lib/core/notifications/app_lifecycle_coordinator.dart`
- Modify: `lib/core/notifications/episode_check_service.dart`
- Modify: `lib/main.dart:37`
- Modify: `test/support/fake_user_data_store.dart`
- Test: `test/notifications/app_lifecycle_coordinator_test.dart`, `test/notifications/episode_check_service_test.dart`, `test/repositories/hive_user_data_store_test.dart`

**Interfaces:**
- Produces:
  - `AppConstants.appForegroundHeartbeatInterval = Duration(minutes: 5)`; `AppConstants.appForegroundHeartbeatStaleAfter = Duration(minutes: 15)`.
  - `StorageConstants.appForegroundHeartbeatAtKey = 'app_foreground_heartbeat_at'`.
  - `HiveUserDataStore.saveAppInForeground(true)` scrive anche l'heartbeat (`DateTime.now()` ISO-8601); `Future<DateTime?> HiveUserDataStore.loadAppForegroundHeartbeatAt()`.
  - `UserDataSnapshot.appForegroundHeartbeatAt` (`DateTime?`, opzionale) e `bool UserDataSnapshot.isAppOpenAt(DateTime now)`: `appInForeground` e heartbeat non nullo e non più vecchio di `appForegroundHeartbeatStaleAfter`.
  - `AppLifecycleCoordinator({required AppServices appServices, Future<void> Function()? clearNewEpisodesNotification, Duration heartbeatInterval = AppConstants.appForegroundHeartbeatInterval})`.
  - `FakeUserDataStore.foregroundWrites` (`List<bool>`): ogni chiamata a `saveAppInForeground`.

- [ ] **Step 1: Scrivere i test**

- Snapshot (in `hive_user_data_store_test.dart` o nuovo `test/repositories/user_data_snapshot_test.dart`): `isAppOpenAt` è `true` con flag `true` e heartbeat di 1 minuto fa; `false` con heartbeat di 16 minuti fa; `false` con heartbeat nullo e flag `true`; `false` con flag `false`.
- Store Hive: dopo `saveAppInForeground(true)`, `loadAppForegroundHeartbeatAt()` non è nullo ed è entro pochi secondi da ora; `readSnapshot()` lo riporta.
- Coordinator, con `testWidgets` (timer in tempo finto) e `heartbeatInterval: Duration(minutes: 5)`:
  - `refreshes the foreground heartbeat while resumed` — `resumed`, poi `tester.pump(Duration(minutes: 5))` → `foregroundWrites == [true, true]`.
  - `stops the heartbeat when paused` — `resumed`, `paused`, `tester.pump(Duration(minutes: 15))` → `foregroundWrites == [true, false]`.
  - Chiamare `coordinator.detach()` a fine test (nessun timer pendente).
- Background:
  - `does not notify while the app is in foreground` — snapshot con `appForegroundHeartbeatAt: DateTime.now()`.
  - `notifies when the foreground flag is stale` — `appInForeground: true`, heartbeat di 1 ora fa → `[(count: 5, silent: false)]`.

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/ test/repositories/`
Expected: FAIL di compilazione (campi e parametri nuovi inesistenti).

- [ ] **Step 3: Implementare**

- Store e snapshot come da Interfaces; cancellare la chiave heartbeat insieme alle altre chiavi di foreground.
- Coordinator: un `Timer?` heartbeat. Su `resumed`: persist `true` e avvio del `Timer.periodic(heartbeatInterval)` che persiste `true` (se già attivo non duplicarlo). Su ogni altro stato: cancellare il timer e persist `false`. `attach()` usa lo stato reale `WidgetsBinding.instance.lifecycleState`: `resumed` → come sopra; `null` → persist `true` una volta, senza timer (scade da solo dopo 15 minuti se non arriva un vero `resumed`); altro → persist `false`. `detach()` cancella il timer.
- `checkAndStore`: sostituire `snapshot.appInForeground` con `snapshot.isAppOpenAt(DateTime.now())`.
- `main.dart`: rimuovere `saveAppInForeground(true)` prima di `runApp` (lo gestisce il coordinator).

- [ ] **Step 4: Eseguire i test e verificare che passino**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit (su conferma dell'utente)**

Messaggio: `Treat a stale foreground flag as closed in the background check`.

---

### Task 3: Aggiornare Continue Watching al rientro (F)

**Files:**
- Modify: `lib/core/services/episode_alerts_service.dart`
- Modify: `lib/core/services/app_services.dart`
- Modify: `lib/core/notifications/app_lifecycle_coordinator.dart`
- Test: `test/services/app_services_persistence_test.dart`

**Interfaces:**
- Produces:
  - `Future<void> EpisodeAlertsService.refreshOnResume({required Duration maxAge, DateTime? now})` — `await importBackgroundCheckResult()`; poi legge `loadLastEpisodeCheckAt()`; se nullo o più vecchio di `maxAge` → `await refresh(forceRefresh: true)`.
  - `EpisodeAlertsService.refresh`: per `forShowId == null`, se un refresh completo è già in corso restituisce lo stesso `Future` (campo `Future<void>? _fullRefreshInFlight`, azzerato a fine esecuzione). I refresh per singolo show restano invariati.
  - `Future<void> AppServices.refreshAlertsOnResume()` — delega con `maxAge: BackgroundTaskRunner.refreshInterval`.
  - Il coordinator, su `resumed`, chiama `refreshAlertsOnResume()` al posto di `importBackgroundCheckResult()`.

- [ ] **Step 1: Scrivere i test**

Nel gruppo `importBackgroundCheckResult` (show seguito senza episodi registrati: il refresh non fa richieste TMDB ma aggiorna `lastEpisodeCheckAt`):
- `refreshes on resume when the last check is old` — `store.lastEpisodeCheckAt = DateTime.now().subtract(Duration(hours: 3))`, nessun risultato background → dopo `refreshAlertsOnResume()`, `store.lastEpisodeCheckAt` è successivo all'inizio del test.
- `skips the refresh on resume when the last check is recent` — `lastEpisodeCheckAt` di 1 ora fa → invariato.

Nel gruppo `AppServices new episode alerts after watch changes` (usa `StubTmdbService`; aggiungere un contatore delle chiamate a `getTvShowSummary` se manca):
- `concurrent full refreshes share one run` — due `refreshNewEpisodeAlertsFromNetwork()` avviati senza attendere, poi `Future.wait` → chiamate summary pari al numero di show seguiti (non il doppio).

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/services/app_services_persistence_test.dart`
Expected: FAIL (metodo inesistente; il test di concorrenza conta il doppio).

- [ ] **Step 3: Implementare come da Interfaces**

- [ ] **Step 4: Eseguire analyze e la suite completa**

Run: `flutter analyze` → `No issues found!`; `flutter test` → tutti PASS.

- [ ] **Step 5: Commit (su conferma dell'utente)**

Messaggio: `Refresh Continue Watching on resume when the last check is old`.

---

### Verifica manuale (facoltativa)

Non coperto dai test: heartbeat reale su dispositivo, comportamento iOS al lancio in background, aggiornamento visibile di Continue Watching al rientro. L'emulatore può essere usato in parallelo dall'utente: verificare prima di segnalare un bug.
