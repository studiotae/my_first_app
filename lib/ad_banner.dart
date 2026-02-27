import 'dart:io'; // ★これがOS判定に必要
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SimpleBannerAd extends StatefulWidget {
  const SimpleBannerAd({super.key});

  @override
  State<SimpleBannerAd> createState() => _SimpleBannerAdState();
}

class _SimpleBannerAdState extends State<SimpleBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // ★これで自動的に「Android」と「iOS」を判別してIDを切り替えます
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-9798347852135431/8804016579' // Android本番用
      : 'ca-app-pub-9798347852135431/2105534835'; // iOS本番用

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    debugPrint('========== 広告読み込み開始 ==========');
    debugPrint('[Ad] Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
    debugPrint('[Ad] AdUnitId: $_adUnitId');
    
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[Ad] ✅ 広告読み込み成功');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('========== 広告読み込み失敗 ==========');
          debugPrint('[Ad] ❌ エラーコード: ${err.code}');
          debugPrint('[Ad] ❌ エラーメッセージ: ${err.message}');
          debugPrint('[Ad] ❌ エラードメイン: ${err.domain}');
          debugPrint('======================================');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // 読み込み中は高さを0にしておく（空白を作らない）
    return const SizedBox.shrink();
  }
}