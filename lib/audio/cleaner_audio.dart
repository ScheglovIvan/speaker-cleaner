import 'package:audioplayers/audioplayers.dart';

/// The bundled cleaning sounds captured from the native app
/// (`app_spec.json` -> `content.audio`; files under `assets/audio/`).
///
/// Each cleaning mode has its own tone; the completion chime plays when a
/// routine or plan day finishes.
enum CleanerSound {
  /// audio_1 (m34a7a3da036b177) — primary water-eject / "Clean Dust" tone,
  /// also the default Cleaner-routine tone.
  cleanDust('audio/audio_1.mp3', 'Clean Dust'),

  /// audio_2 (m6c4c72926b135b0) — vibration / deep-clean tone
  /// ("Vibrate Cleaner" mode).
  vibrate('audio/audio_2.mp3', 'Vibrate Cleaner'),

  /// audio_3 (m0254814e8809eda) — air / blow tone ("Blow to Clean" mode).
  blow('audio/audio_3.mp3', 'Blow to Clean'),

  /// audio_result (mc159b4b3482abd0) — completion sound played when a
  /// cleaning routine / plan day finishes.
  completion('audio/audio_result.mp3', 'Complete');

  const CleanerSound(this.asset, this.label);

  /// Asset path relative to the `assets/` root; `AssetSource` prepends
  /// `assets/`, so this resolves to `assets/audio/<file>.mp3`.
  final String asset;

  /// Human-readable mode name shown on the running Cleaning screen when a mode
  /// (rather than a plan day) drives the routine.
  final String label;
}

/// App-wide audio player for the speaker-cleaner tones.
///
/// A dedicated looping player drives the active cleaning tone (it repeats for
/// the length of the routine) while a separate one-shot player fires the
/// completion chime, so the chime can overlap the tone's fade-out cleanly.
class CleanerAudio {
  CleanerAudio._();

  static final CleanerAudio instance = CleanerAudio._();

  final AudioPlayer _tone = AudioPlayer(playerId: 'cleaner_tone');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'cleaner_sfx');

  /// Starts (or restarts) the cleaning tone for [sound], looping until
  /// [stopTone] is called. Mapped to the "Clean Dust" / "Vibrate Cleaner" /
  /// "Blow to Clean" triggers on screen 0012 and the Cleaner routine.
  Future<void> startTone(CleanerSound sound) async {
    await _tone.stop();
    await _tone.setReleaseMode(ReleaseMode.loop);
    await _tone.play(AssetSource(sound.asset));
  }

  /// Stops the active cleaning tone (e.g. leaving the cleaner or on finish).
  Future<void> stopTone() => _tone.stop();

  /// Plays the one-shot completion chime — the "On cleaning completion"
  /// trigger for routines / plan days (screens 0006 / 0008).
  Future<void> playCompletion() async {
    await _sfx.stop();
    await _sfx.setReleaseMode(ReleaseMode.stop);
    await _sfx.play(AssetSource(CleanerSound.completion.asset));
  }
}
