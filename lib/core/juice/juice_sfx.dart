import 'package:audioplayers/audioplayers.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';

enum SfxClip { dice, coin, stamp, quill, pageTurn, fanfare }

extension SfxClipFile on SfxClip {
  String get file => switch (this) {
        SfxClip.dice => 'dice_clatter.wav',
        SfxClip.coin => 'coin_clink.wav',
        SfxClip.stamp => 'stamp_thunk.wav',
        SfxClip.quill => 'quill_scratch.wav',
        SfxClip.pageTurn => 'page_turn.wav',
        SfxClip.fanfare => 'fanfare.wav',
      };
}

/// Fire-and-forget sound effect player. Never throws; if assets or the
/// platform are unavailable it stays silent for that clip.
class Sfx {
  final JuiceSettings _settings;
  final Map<SfxClip, AudioPlayer> _players = {};
  final Set<SfxClip> _failed = {};

  Sfx({required JuiceSettings settings}) : _settings = settings;

  Future<void> play(SfxClip clip) async {
    if (_settings.state.muted || _failed.contains(clip)) return;
    try {
      final player = _players.putIfAbsent(clip, AudioPlayer.new);
      await player.play(AssetSource('sfx/${clip.file}'), volume: 0.6);
    } catch (_) {
      _failed.add(clip);
    }
  }
}