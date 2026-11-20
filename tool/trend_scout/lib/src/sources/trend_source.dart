import '../models.dart';
import '../seasons.dart';

/// A place we can read trend signals from.
abstract class TrendSource {
  String get name;

  /// Must never throw for ordinary failures; return [] and let the pipeline
  /// record the error via [SourceException] when something is really wrong.
  Future<List<TrendSignal>> fetch(SeasonSpec season, {required int windowDays});
}

class SourceException implements Exception {
  SourceException(this.source, this.message);
  final String source;
  final String message;
  @override
  String toString() => '$source: $message';
}
