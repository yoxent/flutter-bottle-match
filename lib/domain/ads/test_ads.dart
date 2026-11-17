/// Whether the next ad request must use test inventory.
///
/// A debug build always uses test ads. A release build uses [remoteTestAds].
/// The app supplies true when Remote Config has no value, so a missing fetch
/// still requests test ads.
bool resolveTestAds({required bool debugBuild, required bool remoteTestAds}) {
  if (debugBuild) {
    return true;
  }
  return remoteTestAds;
}
