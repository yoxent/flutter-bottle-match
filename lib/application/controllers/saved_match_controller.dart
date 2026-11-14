import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/match_snapshot.dart';
import '../launch_recovery.dart';
import '../providers.dart';

final launchRecoveryProvider = Provider<LaunchRecovery>((ref) {
  return LaunchRecovery(ref.watch(matchRepositoryProvider));
});

/// Loads the active match and pauses it when recovery requires a pause.
final savedMatchProvider = FutureProvider<MatchSnapshot?>((ref) {
  return ref.watch(launchRecoveryProvider).prepare();
});
