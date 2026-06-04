# DhikrFlow — Digital Tasbih

A modern, minimalist Islamic dhikr counter built with **Flutter**. Offline‑first,
distraction‑free, with rich analytics, streaks, and CSV/PDF export.

> Design language: calm emerald greens, warm sand neutrals, and a muted gold
> accent. Inter for UI typography, Amiri for Arabic text. Full light & dark mode.

---

## Features

- **Multiple dhikr categories** — SubhanAllah, Alhamdulillah, Allahu Akbar,
  Astaghfirullah, La ilaha illallah, Durood Sharif + unlimited custom ones, each
  with its own name, Arabic text, description, daily target, icon and color.
- **Digital tasbih counter** — huge one‑tap area, haptic feedback, milestone
  pulses, session / today / lifetime counts, undo, and reset‑with‑confirm.
- **Daily tracking** — every count is stored by local day, per category.
- **Analytics dashboard**
  - *Weekly*: daily bar chart, weekly total & average, most‑used category.
  - *Monthly*: GitHub‑style activity heatmap, category distribution pie, totals,
    current streak.
  - *Yearly*: monthly trend line, yearly total, best month, longest streak.
- **Streak system** — current streak, longest streak, completed‑target days.
- **History & export** — browse by day, filter by preset/custom range &
  category, export to **CSV** or **PDF** via the system share sheet.
- **Settings** — theme (light/auto/dark), haptics, milestone pulse, keep‑screen‑on,
  reorder categories, reset all data. (Cloud sync / Google Sign‑In is scaffolded
  as a "coming soon" entry.)

---

## Tech stack

| Concern            | Choice                                  |
| ------------------ | --------------------------------------- |
| Framework          | Flutter (Material 3)                    |
| State management   | Riverpod (`flutter_riverpod`)           |
| Local database     | SQLite (`sqflite`) — offline first      |
| Charts             | `fl_chart`                              |
| Export             | `csv`, `pdf`, `printing`, `share_plus`  |
| Architecture       | Clean architecture + repository pattern |

---

## Architecture

```
lib/
├── main.dart                      # bootstraps prefs + ProviderScope
├── app.dart                       # MaterialApp + theming
├── core/
│   ├── constants/                 # app constants, default dhikr seed
│   ├── di/providers.dart          # database + repository providers
│   ├── theme/                     # colors, themes, ThemeExtension
│   └── utils/                     # date & number helpers
├── domain/                        # framework‑light business layer
│   ├── entities/                  # DhikrCategory, DailyRecord, Session, analytics
│   └── repositories/              # abstract contracts
├── data/                          # implementation layer
│   ├── datasources/app_database.dart   # SQLite schema + migrations
│   ├── models/                    # row <-> entity mappers
│   ├── repositories/              # CategoryRepositoryImpl, DhikrRepositoryImpl
│   └── services/export_service.dart    # CSV / PDF generation
└── presentation/
    ├── providers/                 # Riverpod state (categories, counter, analytics…)
    ├── widgets/                   # shared UI (cards, rings, charts helpers)
    └── screens/                   # home, counter, categories, analytics, history, settings
```

**Data model**

- `categories(id, name, arabic, transliteration, description, color, icon,
  daily_target, lifetime_count, sort_order, is_archived, created_at)`
- `daily_records(id, category_id, day, count)` — `UNIQUE(category_id, day)`
- `sessions(id, category_id, count, started_at, ended_at)`

`daily_records` is the single source of truth for all analytics; counts roll up
by `day` and `category_id`.

---

## Getting started

> Flutter is **not bundled** in this repo. Install the Flutter SDK first:
> https://docs.flutter.dev/get-started/install

### 1. Generate the native scaffolding & wrapper

The `lib/`, `pubspec.yaml`, and the `android/` source configs are included. Run
this once to fill in the binary pieces (Gradle wrapper jar, launcher icons, iOS
project). It will **not** overwrite the existing Dart or Android config files:

```bash
flutter create . --platforms=android,ios --org com.dhikrcounter
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run

```bash
flutter run
```

---

## Building for release

### Android (Play Store)

1. Create a keystore and an `android/key.properties`:

   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

2. Build the app bundle:

   ```bash
   flutter build appbundle --release
   ```

   The signing config in `android/app/build.gradle` automatically picks up
   `key.properties`; without it, release falls back to debug signing for local
   testing.

### iOS (App Store)

```bash
flutter build ipa --release
```

Open `ios/Runner.xcworkspace` in Xcode to set the signing team and bundle id,
then upload via Xcode / Transporter.

---

## Roadmap (post‑MVP)

Home‑screen widgets · smart reminders · dhikr recommendations · prayer‑time
integration · Ramadan mode · community challenges · multi‑device cloud sync
(Google Sign‑In). The Settings screen already reserves the sync entry point.
