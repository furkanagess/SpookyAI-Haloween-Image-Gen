import 'dart:io';

/// Minimal .env loader: process environment wins, then tool/.env, then the
/// repository-root .env (the app's). Never logs values.
class Env {
  Env._(this._values);

  final Map<String, String> _values;

  static Env load({List<String> files = const ['.env', '../../.env']}) {
    final values = <String, String>{};
    for (final path in files.reversed) {
      final f = File(path);
      if (!f.existsSync()) continue;
      for (final raw in f.readAsLinesSync()) {
        final line = raw.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final i = line.indexOf('=');
        if (i <= 0) continue;
        final k = line.substring(0, i).trim();
        var v = line.substring(i + 1).trim();
        if (v.length >= 2 &&
            (v.startsWith('"') && v.endsWith('"') ||
                v.startsWith("'") && v.endsWith("'"))) {
          v = v.substring(1, v.length - 1);
        }
        values[k] = v;
      }
    }
    values.addAll(Platform.environment);
    return Env._(values);
  }

  String? operator [](String key) {
    final v = _values[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  String? get anthropicKey => this['ANTHROPIC_API_KEY'];
  String? get youtubeKey => this['YOUTUBE_API_KEY'];
}
