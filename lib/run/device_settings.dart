import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../measure/kit.dart';

/// Per-device persisted settings: kit mapping and MIDI latency calibration,
/// keyed by the device name.
class DeviceSettings {
  DeviceSettings(this._p);

  final SharedPreferences _p;

  String _k(String kind, String device) => 'device.$kind.$device';

  /// Unknown device → General MIDI defaults.
  KitMapping mappingFor(String device) {
    final s = _p.getString(_k('mapping', device));
    return s == null ? KitMapping.gm() : KitMapping.decode(s);
  }

  Future<void> saveMapping(String device, KitMapping m) async {
    await _p.setString(_k('mapping', device), m.encode());
  }

  ({double offsetMs, double spreadMs})? latencyFor(String device) =>
      _readLatency(_k('latency', device));

  Future<void> saveLatency(
      String device, double offsetMs, double spreadMs) async {
    await _p.setString(
        _k('latency', device), jsonEncode({'o': offsetMs, 's': spreadMs}));
  }

  ({double offsetMs, double spreadMs})? _readLatency(String key) {
    final s = _p.getString(key);
    if (s == null) return null;
    try {
      final m = jsonDecode(s);
      if (m is Map) {
        return (
          offsetMs: (m['o'] as num).toDouble(),
          spreadMs: (m['s'] as num).toDouble()
        );
      }
    } catch (_) {}
    return null;
  }
}
