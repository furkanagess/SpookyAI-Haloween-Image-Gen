# SpookyAI (Flutter)

Context is expensive here: every tool call re-reads the whole conversation.
Keep it small.

## Working rules
- Read only the lines you need (`sed -n 'a,bp'`, `grep -n`); never `cat` whole large files.
- Write edits as small patches. Do not paste large generated blocks inline when a file edit will do.
- Shorten command output: `flutter test <file> 2>&1 | tail -15`, `dart analyze 2>&1 | grep -E " error " | head`.
- Do not run both `flutter build apk` and `flutter build ios` after every small change; analyze + the affected tests first, builds once at the end of a task.
- One task per session. Suggest `/clear` when switching topics.

## Commands
- Analyze: `dart analyze lib test`
- Tests: `flutter test test/<file>_test.dart`
  (`prompt_builder_test.dart` and `widget_test.dart` are empty files and fail to load; ignore.)
- Regenerate prompt docs: `rm docs/PROMPT_LIBRARY.md && flutter test test/prompt_docs_test.dart`
- Proxy tests: `cd tool/fal_proxy && node --test worker.test.mjs`
- Debug run: `flutter run --dart-define-from-file=.env` (see SECURITY.md)
- Release: `tool/build_release.sh android|ios|all` (reads `.env.production`; never raw `flutter build`)

## Where things live
- Prompt engine, moderation, scene kits: `lib/core/prompt_engine/` (see PROMPT_ARCHITECTURE.md)
- Style library: `lib/features/home/data/services/prompt_service.dart`
- fal calls: `lib/core/services/fal_ai_service.dart`; secrets/endpoints: `lib/core/config/environment_config.dart`
- Token prices: `lib/core/services/token_costs.dart` (pricing decisions are the owner's; do not change)
- Seasons/theme: `lib/core/theme/seasons/`

## Hard rules
- No secret in source or bundled assets (a test enforces this).
- Library prompt text is never shown to users (a test enforces this).
