# Flutter Testing Lab

[![CI](https://github.com/Rahul-K-Jha/flutter_testing_lab/actions/workflows/ci.yml/badge.svg)](https://github.com/Rahul-K-Jha/flutter_testing_lab/actions/workflows/ci.yml)

A small task manager that exists to show practical Flutter testing: **unit**,
**widget** and **integration** tests, run on every push by GitHub Actions.

The task list is printed as a **thermal receipt**. Tasks are line items, done
items get a red rubber stamp, deleting is *voiding*, loading is *printing*
and a failed load is a *paper jam*. The UI is deliberately unusual, but the
code under it is a plain, layered Flutter app built to be tested.

<!-- Add a screenshot here: ![Receipt](docs/receipt.png) -->

## Features

| Feature | On the receipt |
|---|---|
| View tasks | One printed line per task, open first, with totals and progress |
| View a task | Tap a title to open its tear-off **item stub** |
| Add a task | Type an item and press **PRINT**; invalid titles get an inline error |
| Complete a task | Tap `[ ]` on the line, or **MARK AS DONE** on the stub |
| Delete a task | Tap `×` on the line, or **VOID ITEM** on the stub |
| Loading / empty / error | `PRINTING RECEIPT…` / `NO ITEMS ON THIS RECEIPT` / `*** PAPER JAM ***` with **RETRY** |

Toggling and deleting are **optimistic**: the receipt updates at once and
rolls back, with a message, if saving fails.

## Project structure

```
lib/
  main.dart                     runs the app with an in-memory repository
  app.dart                      root widget; repository and clock are injected
  src/
    models/task.dart            immutable Task value type
    logic/
      task_validator.dart       title rules (empty, too long, duplicate)
      task_summary.dart         totals, progress %, receipt sort order
    data/
      task_repository.dart      the storage interface the app depends on
      in_memory_task_repository.dart
    state/task_controller.dart  ChangeNotifier: load/add/toggle/delete
    ui/                         receipt page, item stub, widgets, keys
test/
  helpers/                      fake repository, test data, pump helpers
  unit/                         pure Dart logic, no widgets
  widget/                       screens and widgets, against a fake
integration_test/
  task_flow_test.dart           the full journey on a real device
  flows/task_flow.dart          the journey itself
  robots/receipt_robot.dart     page object used by the journey
```

Layers only point downwards: **UI → controller → repository interface**.
Business rules live in pure functions (`logic/`), so most behaviour is
covered by fast unit tests, and widget tests only need to check the screen.

## Running the app

Requires Flutter **3.47.5** or newer (Dart 3.13.4).

```bash
flutter pub get
```
```bash
flutter run -d chrome
```

Any device works (`flutter devices` lists them). The app starts with four
sample tasks and a short artificial delay, so the printing state is visible.

## Running the tests

| What | Command |
|---|---|
| Everything except integration | `flutter test` |
| Unit tests only | `flutter test test/unit` |
| Widget tests only | `flutter test test/widget` |
| One file | `flutter test test/widget/receipt_states_test.dart` |
| With coverage | `flutter test --coverage` (writes `coverage/lcov.info`) |
| Integration | `flutter test integration_test -d <device>` |

Unit and widget tests need no device and finish in about 10 seconds.

**Integration tests need a real target.** Use any of these:

- an Android emulator or phone: `flutter test integration_test -d <device-id>`
- Linux or macOS desktop: `flutter test integration_test -d linux`
- Windows desktop: `flutter test integration_test -d windows` (needs Visual Studio with the C++ workload)
- Chrome: web devices need `flutter drive` and a running chromedriver; see the
  [Flutter docs](https://docs.flutter.dev/testing/integration-tests#test-in-a-web-browser)

CI runs them on Linux desktop under a virtual display, so you don't need a
device to see them pass.

## What each test covers

**88 unit and widget tests, plus 1 end-to-end integration test.**

### Unit tests: `test/unit/` (56)

| File | Covers |
|---|---|
| `models/task_test.dart` (5) | Defaults, `copyWith`, `toggled`, value equality, `toString` |
| `logic/task_validator_test.dart` (12) | Whitespace normalisation; empty, too-long (exact boundary at 48/49 characters) and duplicate titles; duplicates are case- and space-insensitive and only count open tasks; rule priority |
| `logic/task_summary_test.dart` (8) | Open/done/total counts, progress rounding, "all done" edge cases, receipt sort order and stability, input not mutated |
| `data/in_memory_task_repository_test.dart` (10) | Seeding, read-only snapshots, clock-stamped adds, unique ids that never clash with seeded ones, update/delete, not-found errors |
| `state/task_controller_test.dart` (18) | Uses **mocktail**: status transitions (`loading → ready / failure`), error messages, validation never reaching the repository (`verifyNever`), normalised titles (`verify`), busy flag, optimistic toggle checked with a `Completer`, rollback on failure, safe after `dispose` |
| `ui/receipt_format_test.dart` (3) | Receipt date, time and count formatting |

### Widget tests: `test/widget/` (32)

| File | Covers |
|---|---|
| `receipt_states_test.dart` (7) | **Loading** (held open with a `Completer`), **empty**, **error** with its message, **retry** recovering, field disabled until loaded, lines and totals rendering, date from the injected clock |
| `receipt_interactions_test.dart` (16) | Marking done (stamp, totals, saved, re-sorted), undo, **rollback with snackbar** on failure; voiding (removed, saved, empty state, rollback); adding (success, keyboard submit, each validation error, error cleared on typing, `PRINTING…` blocking double submits, storage failure); opening the item stub |
| `task_detail_page_test.dart` (4) | Stub content, mark done → REOPEN, void → navigates back with snackbar, failed void stays put |
| `task_line_test.dart` (5) | One line in isolation: open vs done styling (strike-through, stamp), each tap target fires its own callback, **screen-reader semantics** (checked state, label, tap action), tooltip |

### Integration test: `integration_test/` (1)

`task_flow_test.dart` runs the **real app** (real controller, real
repository with latency, real navigation) through the whole journey:

> empty receipt → blank title rejected → add two items → duplicate rejected
> → mark one done from the list → open the other, mark it done on its stub,
> go back → void one from its stub → void the other from the list → empty
> receipt again

## Testing techniques used

- **Dependency injection at the root.** `TestingLabApp` takes a
  `TaskRepository` and a clock, so every test runs the real widget tree
  against a fake, with deterministic dates.
- **Fakes and mocks, each where it fits.** Widget tests use a hand-written
  `FakeTaskRepository` that really stores data. The controller's unit tests
  use mocktail to assert exact calls (`verify`, `verifyNever`, `captureAny`).
- **Completer gates** hold an async call open, so a test can assert the
  loading or saving state and then release it. No sleeps, no timers.
- **Keys instead of copy or position.** `ReceiptKeys` gives every widget a
  test touches a stable key. Rows are keyed by task id because they move
  when re-sorted.
- **A robot (page object)** keeps the integration test readable as a user
  story, and its `pumpUntil` loop waits for real async work without
  depending on `pumpAndSettle`, which never settles while a progress bar is
  animating.
- **Accessibility checks** with `ensureSemantics` and `isSemantics`.

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push
and pull request, with two jobs in parallel:

1. **Analyze + unit & widget tests:** format check, `flutter analyze`,
   `flutter test --coverage`, and a coverage summary on the run page.
2. **Integration tests:** installs the Linux desktop toolchain and runs
   `flutter test integration_test -d linux` under `xvfb`.

Flutter is pinned to 3.47.5 in CI so local and CI results match. Bump it in
the workflow when you upgrade locally.

## Credits

Typeset in [Roboto Mono](https://github.com/googlefonts/robotomono)
(Apache 2.0, see `assets/fonts/NOTICE.txt`).
