# Notifiche nuovi episodi — Fase 3 (UX) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Il tap sulla notifica porta alla Home (E); il testo della notifica nomina gli show (H).

**Architecture:** (E) `NotificationService.initialize` riceve un callback per il tap sulla notifica nuovi episodi; `main.dart` lo collega a `mainTabRequests`, un piccolo `ChangeNotifier` che `MainNavigator` ascolta per chiudere le route aperte e selezionare la Home. All'avvio a freddo non serve nulla: la Home è già il tab iniziale. (H) `checkAndStore` riassume gli episodi notificati in `NewEpisodesSummary` (conteggio + titoli degli show); una funzione pura compone il testo; Android usa `BigTextStyleInformation` per mostrarlo per intero.

**Tech Stack:** Flutter / Dart 3, flutter_local_notifications ^22.3.0, intl/ARB (`flutter gen-l10n`), flutter_test con fake scritti a mano.

**Spec:** analisi in conversazione del 2026-11-21, punti E, H. Fasi precedenti: `docs/superpowers/plans/2026-11-21-new-episode-notifications-phase1.md`, `...-phase2.md`.

- **E** — nessun `onDidReceiveNotificationResponse` in [notification_service.dart](../../../lib/core/notifications/notification_service.dart): con l'app in background su un altro tab, il tap la riapre lì.
- **H** — testo generico ("N new episodes available"), senza titoli.

## Global Constraints

- Branch: `fix/new-episode-notifications`. Non cambiarlo.
- Nessun commit autonomo: a fine task mostrare le modifiche e chiedere all'utente se committare. I passi "Commit" indicano file e messaggio proposti.
- Nessuna nuova dipendenza; schema Hive, outbox e backup invariati.
- Stringhe solo in `lib/l10n/app_en.arb`; dopo ogni modifica `flutter gen-l10n` e inclusione dei file generati (`lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`).
- Test: fake scritti a mano; fake condiviso `test/support/fake_user_data_store.dart`.
- File in CRLF: preservare i fine riga. `dart format` solo sulle righe toccate; ripristinare a mano righe preesistenti riformattate.
- `flutter analyze` a `No issues found!`; `flutter test` tutto verde.
- Commenti in inglese solo dove la logica non è ovvia. Commit in inglese con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. Tap con un bottom sheet o una route aperta sopra i tab: va chiusa, altrimenti il cambio di tab resta invisibile → test in Task 1.
2. Tap su una notifica diversa da quella dei nuovi episodi (id ≠ 1): nessun cambio di tab → test in Task 1.
3. Episodi notificati il cui alert non è più tra gli alert correnti: contano nel numero ma non aggiungono titoli; con zero titoli si usa il testo generico attuale → test in Task 2.
4. Più episodi dello stesso show: il titolo compare una volta sola → test in Task 2.
5. Titolo show vuoto (alert legacy): ignorato nell'elenco → test in Task 2.

---

### Task 1: Il tap sulla notifica apre la Home (E)

**Files:**
- Create: `lib/presentation/navigation/main_tab.dart`
- Modify: `lib/presentation/navigation/main_navigator.dart`
- Modify: `lib/core/notifications/notification_service.dart` (`initialize`)
- Modify: `lib/main.dart` (`_bootstrapAfterFirstFrame`)
- Test: `test/notifications/notification_service_test.dart` (nuovo), `test/widgets/main_navigator_test.dart` (nuovo)

**Interfaces:**
- Produces:
  - `main_tab.dart`: `enum MainTab { home, search, catalogue, settings }` (spostato da `main_navigator.dart`, che lo ri-esporta con `export 'main_tab.dart' show MainTab;`); `class MainTabRequests extends ChangeNotifier` con `void show(MainTab tab)` (memorizza la richiesta e notifica) e `MainTab? take()` (restituisce e azzera la richiesta); istanza globale `final MainTabRequests mainTabRequests`.
  - `MainNavigator({super.key, MainTabRequests? tabRequests})` — default `mainTabRequests`. In `initState` ascolta e gestisce subito una richiesta già pendente; in `dispose` smette di ascoltare. Gestione: `take()`; se non nullo, `appNavigatorKey.currentState?.popUntil((route) => route.isFirst)` e selezione del tab.
  - `NotificationService.initialize({..., VoidCallback? onNewEpisodesTap})`: passa a `_plugin.initialize` un `onDidReceiveNotificationResponse` che invoca il callback solo se `isNewEpisodesResponse(response)`.
  - `@visibleForTesting static bool NotificationService.isNewEpisodesResponse(NotificationResponse response)` — `response.id == _newEpisodesNotificationId`.
  - `main.dart`: `onNewEpisodesTap: () => mainTabRequests.show(MainTab.home)`.

- [ ] **Step 1: Scrivere i test**

- `notification_service_test.dart`: `recognizes a tap on the new episodes notification` — `NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, id: 1)` → `true`; con `id: 2` → `false`; con `id: null` → `false`.
- `main_navigator_test.dart` (preparazione come `test/widgets/catalogue_screen_test.dart`: `AppServices().userDataStore = FakeUserDataStore()`; se un tab richiede TMDB, impostare uno stub `AppServices().tmdbService`). App di prova: `MaterialApp(navigatorKey: appNavigatorKey, localizationsDelegates/supportedLocales come main.dart, home: MainNavigator(tabRequests: requests))`.
  - `shows Home when a tab request arrives` — tap sulla destinazione Settings, `requests.show(MainTab.home)`, `pumpAndSettle` → `NavigationBar.selectedIndex == 0`.
  - `closes an open sheet before showing Home` — da Settings, `showModalBottomSheet` con un `Text('sheet')`, `requests.show(MainTab.home)`, `pumpAndSettle` → `find.text('sheet')` non trovato e `selectedIndex == 0`.
  - `handles a request made before it was built` — `requests.show(MainTab.home)` prima del `pumpWidget` → dopo il pump `requests.take()` è `null`.

Se `MainNavigator` non si riesce a montare nei test senza rete, fermarsi e riportarlo invece di cambiare i tab.

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/notification_service_test.dart test/widgets/main_navigator_test.dart`
Expected: FAIL di compilazione (`isNewEpisodesResponse`, `MainTabRequests`, `tabRequests` inesistenti).

- [ ] **Step 3: Implementare come da Interfaces**

- [ ] **Step 4: Eseguire i test e verificare che passino**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit (su conferma dell'utente)**

File: quelli sopra + questo piano. Messaggio: `Open Home when the new episodes notification is tapped`.

---

### Task 2: Il testo della notifica nomina gli show (H)

**Files:**
- Create: `lib/core/notifications/new_episodes_summary.dart`
- Create: `lib/core/notifications/new_episodes_notification_text.dart`
- Modify: `lib/core/notifications/episode_check_service.dart`
- Modify: `lib/core/notifications/notification_service.dart` (`showNewEpisodesNotification`)
- Modify: `lib/l10n/app_en.arb` + file generati
- Test: `test/notifications/new_episodes_summary_test.dart`, `test/notifications/new_episodes_notification_text_test.dart` (nuovi), `test/notifications/episode_check_service_test.dart`

**Interfaces:**
- Produces:
  - `new_episodes_summary.dart`: `class NewEpisodesSummary { final int episodeCount; final List<String> showTitles; }` (costruttore `const`) e `NewEpisodesSummary summarizeNotifiedEpisodes({required Iterable<int> episodeIds, required Iterable<NewEpisodeAlert> alerts})` — `episodeCount` = numero di id; `showTitles` = titoli non vuoti, senza duplicati, nell'ordine di `alerts`, degli alert che contengono almeno uno degli id (`alertEpisodeIds` da `episode_notification_policy.dart`).
  - `typedef NewEpisodesNotifier = Future<bool> Function(NewEpisodesSummary summary, {required bool silent});`
  - `checkAndStore`: costruisce il riepilogo con `summarizeNotifiedEpisodes(episodeIds: candidateNotifiedAt.keys, alerts: alerts)`.
  - `NotificationService.showNewEpisodesNotification({required NewEpisodesSummary summary, bool silent = false})` — `false` anche se `summary.episodeCount <= 0`. Android: `styleInformation: BigTextStyleInformation(body)`.
  - `new_episodes_notification_text.dart`: `String newEpisodesNotificationBody(AppLocalizations l10n, NewEpisodesSummary summary)`.
  - Nuove chiavi ARB (testi esatti):
    - `notificationBodyOneShow`: `"{count, plural, =1{A new episode of {show}} other{{count} new episodes of {show}}}"` — placeholder `count` (int), `show` (String).
    - `notificationBodyTwoShows`: `"{count} new episodes of {first} and {second}"` — `count` (int), `first`, `second` (String).
    - `notificationBodyManyShows`: `"{count} new episodes of {first}, {second} and {others, plural, =1{1 more show} other{{others} more shows}}"` — `count`, `others` (int), `first`, `second` (String).
    - `notificationBodyOne` / `notificationBodyOther` restano: sono il testo con zero titoli.

- [ ] **Step 1: Scrivere i test**

- Riepilogo: alert dello show A con episodio 12 e `laterAiredEpisodes` [13], show B con 22, show C con 32.
  - `counts ids and lists each show once` — id {12, 13, 22} → `episodeCount == 3`, `showTitles == ['A', 'B']`.
  - `keeps the count for ids without an alert` — id {12, 99} → `2`, `['A']`.
  - `skips empty show titles` — alert con `showTitle: ''` → titolo non elencato.
- Testo (con `lookupAppLocalizations(const Locale('en'))`):
  - 0 titoli, 1 episodio → `l10n.notificationBodyOne`; 0 titoli, 3 episodi → `l10n.notificationBodyOther(3)`.
  - `['A']`, 1 → `'A new episode of A'`; `['A']`, 3 → `'3 new episodes of A'`.
  - `['A', 'B']`, 2 → `'2 new episodes of A and B'`.
  - `['A', 'B', 'C']`, 4 → `'4 new episodes of A, B and 1 more show'`; `['A', 'B', 'C', 'D']`, 5 → `'5 new episodes of A, B and 2 more shows'`.
- Background: i notifier registrano `(count: summary.episodeCount, silent: silent)` (aspettative esistenti invariate). Nuovo `names the shows in the notification` — stub normale, blocco unico → `summary.showTitles == ['Show 1', 'Show 2', 'Show 3', 'Show 4', 'Show 5']` (o nell'ordine degli alert salvati).

- [ ] **Step 2: Eseguire i test e verificare che falliscano**

Run: `flutter test test/notifications/`
Expected: FAIL di compilazione.

- [ ] **Step 3: Implementare come da Interfaces; `flutter gen-l10n`**

- [ ] **Step 4: Eseguire analyze e la suite completa**

Run: `flutter analyze` → `No issues found!`; `flutter test` → tutti PASS.

- [ ] **Step 5: Commit (su conferma dell'utente)**

Messaggio: `Name the shows in the new episodes notification`.

---

### Verifica manuale (facoltativa)

Non coperto dai test: tap reale sulla notifica con l'app in background, testo espanso su Android, testo su iOS. L'emulatore può essere usato in parallelo dall'utente: verificare prima di segnalare un bug.
