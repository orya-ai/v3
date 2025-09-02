import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orya/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:math';
import 'package:vibration/vibration.dart';

import '../application/truth_or_dare_service.dart';
import 'widgets/custom_roulette_wheel.dart';

class TruthOrDareRoulettePage extends ConsumerStatefulWidget {
  const TruthOrDareRoulettePage({super.key});

  @override
  ConsumerState<TruthOrDareRoulettePage> createState() => _TruthOrDareRoulettePageState();
}

class _TruthOrDareRoulettePageState extends ConsumerState<TruthOrDareRoulettePage> {
  final StreamController<int> _wheelController = StreamController<int>();
  int _selectedIndex = 0;
  String _result = ''; // The resulting question

  // Simplified wheel slices: just Colors → for T, D, or C
  final List<Color> _sliceColors = [
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.green,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.green,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
    Colors.red,
    Colors.black,
  ];

  late final List<WheelSlice> _wheelSlices;

  @override
  void initState() {
    super.initState();

    _wheelSlices = _sliceColors.map((color) {
      String text;
      if (color == Colors.red) {
        text = 'D'; // Dare
      } else if (color == Colors.black) {
        text = 'T'; // Truth
      } else {
        text = 'C'; // Choice
      }

      return WheelSlice(
        color: color,
        text: text,
        textColor: Colors.white,
        borderColor: AppTheme.primaryTextColor,
      );
    }).toList();
  }

  @override
  void dispose() {
    _wheelController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Truth or Dare Roulette'),
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryTextColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fortune Wheel
            SizedBox(
              width: 300,
              height: 300,
              child: CustomRouletteWheel(
                slices: _wheelSlices,
                selectedStream: _wheelController.stream,
                onSpinComplete: () {
                  final selectedColor = _sliceColors[_selectedIndex];
                  String gameMode;

                  if (selectedColor == Colors.red) {
                    gameMode = 'dare';
                  } else if (selectedColor == Colors.green) {
                    gameMode = 'choice';
                  } else {
                    gameMode = 'truth';
                  }

                  ref.read(truthOrDareProvider.notifier).getQuestion(gameMode);
                },
              ),
            ),

            // Result display area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBackgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _result.isEmpty
                    ? 'Spin the wheel to get a question.'
                    : _result,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryTextColor,
                    ),
              ),
            ),

            // Spin Button
            ElevatedButton(
              onPressed: ref.watch(truthOrDareProvider).isSpinning
                  ? null
                  : () {
                      Vibration.vibrate(duration: 50);
                      final random = Random();
                      _selectedIndex = random.nextInt(_wheelSlices.length);
                      _wheelController.add(_selectedIndex);
                      ref.read(truthOrDareProvider.notifier).startSpin();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryButtonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
              ),
              child: const Text(
                'SPIN',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}