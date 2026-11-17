# Bottle Match

A portrait-first, shared-device party puzzle for Android, iOS, and the browser. Players take turns on one device. There is no account, backend, or online multiplayer.

This repository is the runnable Flutter application. Design notes, architecture decisions, and the rules status live in `E:\Projects\Docs\flutter-bottle-match\Flutter\flutter-bottle-match`.

## Privacy

The privacy policy is published at <https://yoxent.github.io/flutter-bottle-match/>.

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

Setup, turns, the hidden-order bottle board, pause, and the championship are playable on Android, iOS, and the web. Each player chooses an icon, shown in that player's color from the shared piece palette. Player order is Linear, Snake, Rotating, or Random. Setup shows the name and what it does. Review shows the name only. Every round opens with that order before Begin round. Begin round opens the board for the first player and starts the timer when one is set. A check that is not the hidden order covers the board until the next player presses Play, which starts that player's timer when one is set. A new match deals a secret bottle order. Players swap bottles and submit one arrangement per turn. The app scores the first exact order. A version 1 save still records the round winner by hand.
