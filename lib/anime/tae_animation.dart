import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class TaeRandomLoadingAnimation extends StatefulWidget {
  final double width;
  final double height;

  const TaeRandomLoadingAnimation({
    Key? key,
    this.width = 250,
    this.height = 250,
  }) : super(key: key);

  @override
  _TaeRandomLoadingAnimationState createState() => _TaeRandomLoadingAnimationState();
}

class _TaeRandomLoadingAnimationState extends State<TaeRandomLoadingAnimation> {
  Timer? _timer;
  int _currentPatternIndex = 0;
  int _currentFrameIndex = 0;

  // アニメーションパターンの登録
  final List<List<String>> _animationPatterns = [
    // パターンA：基本の焦り
    [
      'assets/PC1.png',
      'assets/PC2.png',
      'assets/PC1.png',
      'assets/PC2.png',

    ],
    // パターンB：突っ伏す
    [
      'assets/print1.png',
      'assets/print2.png',
      'assets/print3.png',
      'assets/print4.png',
    ],

    [
      'assets/fry1.png',
      'assets/fry2.png',
      'assets/fry3.png',
      'assets/fry4.png',
      'assets/fry5.png',
      'assets/fry6.png',
    ],

    [
      'assets/bike.png',
      'assets/bike.png',
    ],
  ];

  @override
  void initState() {
    super.initState();
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      setState(() {
        int frameLength = _animationPatterns[_currentPatternIndex].length;
        if (_currentFrameIndex < frameLength - 1) {
          _currentFrameIndex++;
        } else {
          _pickNextRandomPattern();
        }
      });
    });
  }

  void _pickNextRandomPattern() {
    final random = Random();
    int nextPattern;
    do {
      nextPattern = random.nextInt(_animationPatterns.length);
    } while (_animationPatterns.length > 1 && nextPattern == _currentPatternIndex);

    _currentPatternIndex = nextPattern;
    _currentFrameIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentImage = _animationPatterns[_currentPatternIndex][_currentFrameIndex];

    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Image.asset(
            currentImage,
            key: ValueKey<String>(currentImage),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}