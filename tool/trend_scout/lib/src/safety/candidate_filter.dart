import 'package:spooky_ai/core/prompt_engine/prompt_moderation.dart';

import '../models.dart';

/// Runs every candidate through the app's own safety gate (so nothing the
/// robot proposes could ever be blocked in the app) and flags likely
/// trademark / real-person references for human review.
class CandidateFilter {
  const CandidateFilter({this.strict = false});

  /// In strict mode flagged candidates are dropped, not just warned.
  final bool strict;

  static const brandWords = [
    'disney',
    'pixar',
    'marvel',
    'dc comics',
    'batman',
    'spider-man',
    'spiderman',
    'pokemon',
    'pikachu',
    'nintendo',
    'mario',
    'zelda',
    'harry potter',
    'hogwarts',
    'star wars',
    'jedi',
    'mickey',
    'minnie',
    'barbie',
    'squid game',
    'stranger things',
    'wednesday addams',
    'netflix',
    'coca-cola',
    'coca cola',
    'hello kitty',
    'minecraft',
    'fortnite',
    'ghostface',
    'scream mask',
    'michael myers',
    'freddy krueger',
    'jason voorhees',
    'grinch',
    'elsa',
    'frozen',
    'home alone',
    'taylor swift',
    'kardashian',
    'studio ghibli',
    'ghibli',
    'simpsons',
    'one piece',
    'naruto',
    'demon slayer',
  ];

  List<PromptCandidate> apply(List<PromptCandidate> candidates) {
    final out = <PromptCandidate>[];
    for (final c in candidates) {
      final mod = PromptModeration.check('${c.title} ${c.prompt}');
      if (!mod.allowed) {
        c.blockedReason = 'moderation:${mod.category!.name}';
        out.add(c);
        continue;
      }
      final text = '${c.title} ${c.prompt} ${c.tags.join(' ')}'.toLowerCase();
      final brands = brandWords
          .where((b) => RegExp('\\b${RegExp.escape(b)}\\b').hasMatch(text))
          .toList();
      if (brands.isNotEmpty) {
        if (strict) {
          c.blockedReason = 'brand:${brands.join(",")}';
        } else {
          c.warnings.add(
            'possible trademark/real-person reference: '
            '${brands.join(", ")} — rewrite generically',
          );
        }
      }
      if (c.prompt.length < 40) {
        c.warnings.add('prompt is very short');
      }
      if (c.prompt.length > 500) {
        c.warnings.add('prompt exceeds app limit (500)');
      }
      out.add(c);
    }
    return out;
  }
}
