import 'package:flutter/widgets.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preferPortraitOnPhones();
  try {
    final dependencies = await AppDependencies.open();
    runApp(dependencies.scope(const ColorfulBottleMatchApp()));
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(StartupFailureApp(details: '$error'));
  }
}
