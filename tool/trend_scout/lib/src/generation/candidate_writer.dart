import '../models.dart';
import '../seasons.dart';
import 'claude_client.dart';

/// Writes prompt candidates for concepts — with Claude when a key is
/// present, otherwise from templates (clearly marked `origin: template`).
class CandidateWriter {
  CandidateWriter({
    this.claude,
    this.textPerConcept = 1,
    this.imagePerConcept = 1,
  });

  final ClaudeClient? claude;
  final int textPerConcept;
  final int imagePerConcept;

  bool get usesLlm => claude != null;

  /// Returns (concepts, candidates). With an LLM the concepts are re-clustered
  /// by Claude from the raw signals; offline the given [heuristic] concepts
  /// are used as-is.
  Future<(List<TrendConcept>, List<PromptCandidate>)> write({
    required SeasonSpec season,
    required List<TrendSignal> signals,
    required List<TrendConcept> heuristic,
    required int maxConcepts,
  }) async {
    if (claude == null) {
      return (heuristic, _fromTemplates(season, heuristic));
    }
    final llm = await _fromClaude(season, signals, heuristic, maxConcepts);
    return llm;
  }

  // ------------------------------------------------------------- Claude

  static const _schema = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['concepts'],
    'properties': {
      'concepts': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'name',
            'why_trending',
            'keywords',
            'evidence_titles',
            'candidates',
          ],
          'properties': {
            'name': {'type': 'string'},
            'why_trending': {'type': 'string'},
            'keywords': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'evidence_titles': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'candidates': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['mode', 'title', 'prompt', 'tags'],
                'properties': {
                  'mode': {
                    'type': 'string',
                    'enum': ['text', 'image'],
                  },
                  'title': {'type': 'string'},
                  'prompt': {'type': 'string'},
                  'tags': {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                },
              },
            },
          },
        },
      },
    },
  };

  String _system(SeasonSpec season) =>
      '''
You are the trend analyst and prompt writer for SpookyAI, a mobile app that
generates ${season.displayName}-themed images. Two modes exist:
- text: FLUX text-to-image. The user prompt is the SUBJECT ONLY; the app
  appends scene/lighting/style boilerplate itself. Write 1–2 vivid, concrete
  sentences describing subject, wardrobe/props, setting and mood. No quality
  tags, no "4k", no negative prompts.
- image: photo transformation that keeps the person's face. Start with
  "the person as …" or "the person in …" (never "Transform"), then describe
  costume, makeup, hair, props and expression. The face must stay open and
  visible and recognizable: no masks over the face, no head replacements, no
  full-face fur or fully wrapped bandages; makeup follows their own features.
  Use natural wording — avoid "flawless", "perfect", "glowing skin",
  "ultra", "hyper". Keep costume-only prompts under 230 characters. Do NOT mention faces,
  identity or "same person" — the app adds that itself. Only describe an
  environment and lighting when the look is inseparable from a place (a retro
  bedroom, a carnival); otherwise leave the place out — the app adds a
  matching one.

Rules:
- Cluster the evidence into distinct visual concepts people would actually
  want to make of themselves or share. Merge near-duplicates.
- Prefer concepts that are clearly rising now, not evergreen clichés.
- No sexual content, no realistic violence or gore, no hate, no self-harm.
  Spooky/festive genre imagery is fine.
- Avoid trademarked characters, franchises and named real people (e.g. no
  Disney, Marvel, celebrity names). Describe the look generically instead.
- Titles: 2–4 words, Title Case. Tags: 3–6 lowercase single words.
- For each concept write $textPerConcept text candidate(s) and
  $imagePerConcept image candidate(s). English only.
''';

  Future<(List<TrendConcept>, List<PromptCandidate>)> _fromClaude(
    SeasonSpec season,
    List<TrendSignal> signals,
    List<TrendConcept> heuristic,
    int maxConcepts,
  ) async {
    final top = signals.take(150).toList();
    final buf = StringBuffer()
      ..writeln('Season: ${season.displayName}')
      ..writeln('Return at most $maxConcepts concepts, strongest first.')
      ..writeln()
      ..writeln('Evidence (score 0-1 | source | title):');
    for (final s in top) {
      buf.writeln(
        '${s.score.toStringAsFixed(2)} | ${s.source} | ${s.title}'
        '${s.note != null ? ' — ${s.note}' : ''}',
      );
    }
    if (heuristic.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(
          'Frequent phrases (heuristic, for reference): '
          '${heuristic.take(12).map((c) => c.name).join('; ')}',
        );
    }

    final json = await claude!.structured(
      system: _system(season),
      user: buf.toString(),
      schema: _schema,
    );

    final byTitle = {for (final s in signals) s.title.toLowerCase(): s};
    final concepts = <TrendConcept>[];
    final candidates = <PromptCandidate>[];
    for (final c in (json['concepts'] as List).cast<Map<String, dynamic>>()) {
      final ev = <TrendSignal>[];
      for (final t in (c['evidence_titles'] as List).cast<String>()) {
        final hit =
            byTitle[t.toLowerCase()] ??
            byTitle.entries
                .where(
                  (e) =>
                      e.key.contains(t.toLowerCase()) ||
                      t.toLowerCase().contains(e.key),
                )
                .map((e) => e.value)
                .firstOrNull;
        if (hit != null) ev.add(hit);
      }
      final strength = ev.isEmpty
          ? 20.0
          : (ev.fold(0.0, (a, s) => a + s.score) / ev.length * 100);
      final concept = TrendConcept(
        name: c['name'] as String,
        keywords: (c['keywords'] as List).cast<String>(),
        strength: strength,
        evidence: ev,
        whyTrending: c['why_trending'] as String,
      );
      concepts.add(concept);
      for (final k in (c['candidates'] as List).cast<Map<String, dynamic>>()) {
        final mode = k['mode'] == 'image' ? PromptMode.image : PromptMode.text;
        candidates.add(
          PromptCandidate(
            id: _id(season, concept.name, mode, candidates.length),
            title: k['title'] as String,
            mode: mode,
            prompt: (k['prompt'] as String).trim(),
            tags: (k['tags'] as List).cast<String>(),
            concept: concept.name,
            trendScore: strength,
            origin: 'llm',
          ),
        );
      }
    }
    concepts.sort((a, b) => b.strength.compareTo(a.strength));
    return (concepts, candidates);
  }

  // ---------------------------------------------------------- templates

  List<PromptCandidate> _fromTemplates(
    SeasonSpec season,
    List<TrendConcept> concepts,
  ) {
    final out = <PromptCandidate>[];
    for (final c in concepts) {
      final kw = c.keywords.join(' ');
      final title = _titleCase(c.name);
      out.add(
        PromptCandidate(
          id: _id(season, c.name, PromptMode.text, out.length),
          title: title,
          mode: PromptMode.text,
          prompt:
              'A striking ${season.displayName} scene built around $kw, '
              'with rich props and an atmospheric setting that makes the idea instantly readable.',
          tags: [...c.keywords.take(4), season.id],
          concept: c.name,
          trendScore: c.strength,
          origin: 'template',
          warnings: ['template prompt — rewrite before shipping'],
        ),
      );
      out.add(
        PromptCandidate(
          id: _id(season, c.name, PromptMode.image, out.length),
          title: title,
          mode: PromptMode.image,
          prompt:
              'Transform the person into a $kw look for ${season.displayName}: '
              'matching outfit and props, a fitting environment and mood, natural skin texture.',
          tags: [...c.keywords.take(4), season.id],
          concept: c.name,
          trendScore: c.strength,
          origin: 'template',
          warnings: ['template prompt — rewrite before shipping'],
        ),
      );
    }
    return out;
  }

  static String _id(SeasonSpec season, String concept, PromptMode mode, int n) {
    final slug = concept
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${season.id}_${mode.name}_${slug}_$n';
  }

  static String _titleCase(String s) => s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
