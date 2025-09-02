import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. State class
class TruthOrDareState {
  final String result;
  final bool isSpinning;

  TruthOrDareState({this.result = '', this.isSpinning = false});

  TruthOrDareState copyWith({String? result, bool? isSpinning}) {
    return TruthOrDareState(
      result: result ?? this.result,
      isSpinning: isSpinning ?? this.isSpinning,
    );
  }
}

// 2. StateNotifier
class TruthOrDareNotifier extends StateNotifier<TruthOrDareState> {
  TruthOrDareNotifier() : super(TruthOrDareState());

  final _truths = [
    'What is your biggest fear?',
    'What is the most embarrassing thing you have ever done?',
    'What is a secret you have never told anyone?',
    'Who is your secret crush?',
    'What is your most treasured memory?',
  ];

  final _dares = [
    'Do 10 push-ups.',
    'Sing a song out loud.',
    'Talk in a funny accent for the next 3 rounds.',
    'Let someone else post a status on your social media.',
    'Do your best dance move.',
  ];

  void startSpin() {
    state = state.copyWith(isSpinning: true, result: '');
  }

  void getQuestion(String gameMode) {
    final random = Random();
    String result;

    if (gameMode == 'truth') {
      result = 'Truth: ${_truths[random.nextInt(_truths.length)]}';
    } else if (gameMode == 'dare') {
      result = 'Dare: ${_dares[random.nextInt(_dares.length)]}';
    } else { // choice
      result = "Player's Choice: Truth or Dare?";
    }

    state = state.copyWith(isSpinning: false, result: result);
  }

  Future<void> spinWheel() async {
    startSpin();

    // Simulate spinning delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final isTruth = random.nextBool();
    getQuestion(isTruth ? 'truth' : 'dare');
  }
}

// 3. Provider
final truthOrDareProvider = StateNotifierProvider<TruthOrDareNotifier, TruthOrDareState>((ref) {
  return TruthOrDareNotifier();
});
