import 'dart:async';

import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../../core/constants/levelplay_ads.dart';
import '../../domain/ads/match_ads.dart';

/// LevelPlay banner and interstitial for one app session.
class LevelPlayMatchAds
    implements
        MatchAds,
        LevelPlayInitListener,
        LevelPlayInterstitialAdListener {
  final _listeners = <void Function()>[];
  LevelPlayInterstitialAd? _interstitial;
  Completer<void>? _showDone;
  var _bannerReady = false;
  var _starting = false;

  @override
  bool get isBannerReady => _bannerReady;

  @override
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  Future<void> start({required bool testAds}) async {
    if (_starting) {
      return;
    }
    _starting = true;
    try {
      if (testAds) {
        await LevelPlay.setAdaptersDebug(true);
      }
      await LevelPlay.init(
        initRequest: LevelPlayInitRequest.builder(LevelPlayAds.appKey).build(),
        initListener: this,
      );
    } catch (_) {
      _starting = false;
    }
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    final interstitial = LevelPlayInterstitialAd(
      adUnitId: LevelPlayAds.interstitialAdUnitId,
    );
    interstitial.setListener(this);
    _interstitial = interstitial;
    unawaited(interstitial.loadAd());
    _bannerReady = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    _starting = false;
  }

  @override
  Future<void> showMatchCompletedAd() async {
    final interstitial = _interstitial;
    if (interstitial == null || _showDone != null) {
      return;
    }
    final ready = await _isReady(interstitial);
    if (!ready) {
      return;
    }
    final done = Completer<void>();
    _showDone = done;
    try {
      await interstitial.showAd();
      await done.future.timeout(const Duration(minutes: 2));
    } catch (_) {
      _finishShow();
    }
  }

  Future<bool> _isReady(LevelPlayInterstitialAd interstitial) async {
    try {
      return await interstitial.isAdReady();
    } catch (_) {
      return false;
    }
  }

  void _finishShow() {
    final done = _showDone;
    _showDone = null;
    if (done != null && !done.isCompleted) {
      done.complete();
    }
  }

  void _loadAgain() {
    final interstitial = _interstitial;
    if (interstitial == null) {
      return;
    }
    unawaited(interstitial.loadAd());
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLoadFailed(LevelPlayAdError error) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    _finishShow();
    _loadAgain();
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    _finishShow();
    _loadAgain();
  }
}
