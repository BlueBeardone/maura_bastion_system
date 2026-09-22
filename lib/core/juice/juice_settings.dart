import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JuiceState {
  final bool muted;

  const JuiceState({required this.muted});
}

class JuiceSettings extends Cubit<JuiceState> {
  static const _key = 'juice_muted';
  final SharedPreferences _prefs;

  JuiceSettings({required SharedPreferences prefs})
      : _prefs = prefs,
        super(JuiceState(muted: prefs.getBool(_key) ?? false));

  void setMuted(bool muted) {
    _prefs.setBool(_key, muted);
    emit(JuiceState(muted: muted));
  }

  void toggle() => setMuted(!state.muted);
}
