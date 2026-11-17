import 'dart:io';

import 'package:flutter_bottle_match/core/constants/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the home version is the pubspec version name', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec);
    final name = declared?.group(1)?.split('+').first;

    expect(name, AppInfo.version);
  });
}
