# Colorful Bottle Match

A portrait-first, shared-device party puzzle for Android, iOS, and the browser. Players take turns on one device. There is no account, backend, or online multiplayer.

This repository is the runnable Flutter application. Design notes, architecture decisions, and the rules status live in `E:\Projects\Docs\flutter-bottle-match\Flutter\flutter-bottle-match`.

## Requirements

- Flutter 3.44.0
- Dart 3.12.0

Forui 0.26 and later need Flutter 3.47, so this project pins Forui 0.25.0. Do not upgrade Forui until the Flutter SDK is upgraded on purpose.

## Setup

```bash
flutter pub get
```

## Run

```bash
flutter run -d android
flutter run -d chrome
```

iOS requires a Mac with Xcode:

```bash
flutter run -d ios
```

The phone layout is portrait. Tablets and the browser can use a wider window; the game column stays centered.

## Checks

```bash
dart format .
flutter analyze
flutter test
```

## What is implemented

The foundation includes the design tokens, app shell, navigation, domain rules for match setup, turn order, scoring, goals, and phase changes, plus local recovery of one saved match.

Physical Companion setup and turn flow are the next milestone. Fully Digital is Release 2. Its hidden-order puzzle is a proposed mechanic and is not playable.
