import 'package:flutter/material.dart';
import '../theme/gold_theme.dart';

enum Tempo { cepat, santai }

extension TempoExt on Tempo {
  String get label => this == Tempo.cepat ? 'Cepat' : 'Santai';
}

enum ClockOption { tanpa, kilat, cepat, santai }

extension ClockOptionExt on ClockOption {
  String get label {
    switch (this) {
      case ClockOption.tanpa:
        return 'Tanpa jam';
      case ClockOption.kilat:
        return 'Kilat 3+2';
      case ClockOption.cepat:
        return 'Cepat 5+0';
      case ClockOption.santai:
        return 'Santai 10+0';
    }
  }

  int get initialMs {
    switch (this) {
      case ClockOption.tanpa:
        return 0;
      case ClockOption.kilat:
        return 3 * 60 * 1000;
      case ClockOption.cepat:
        return 5 * 60 * 1000;
      case ClockOption.santai:
        return 10 * 60 * 1000;
    }
  }

  int get incrementMs {
    switch (this) {
      case ClockOption.tanpa:
        return 0;
      case ClockOption.kilat:
        return 2000;
      case ClockOption.cepat:
        return 0;
      case ClockOption.santai:
        return 0;
    }
  }
}

class GameSettings {
  final Tempo tempo;
  final ClockOption clock;
  final bool animation;

  const GameSettings({
    this.tempo = Tempo.santai,
    this.clock = ClockOption.tanpa,
    this.animation = true,
  });

  Duration get moveDuration {
    if (!animation) return Duration.zero;
    return tempo == Tempo.cepat
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 350);
  }

  Duration get aiDelay {
    if (tempo == Tempo.santai) {
      return const Duration(milliseconds: 600);
    }
    return Duration.zero;
  }

  bool get calm => tempo == Tempo.santai;

  Color get background =>
      calm ? GoldTheme.calmBackground : GoldTheme.background;
}
