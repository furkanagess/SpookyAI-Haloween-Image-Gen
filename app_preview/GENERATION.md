# Üretim hattı (prompt → fal → sonuç)

Ayrıntılı kurallar: `PROMPT_ARCHITECTURE.md`. Prompt'lar kısa ve betimleyici
kalır; tek yüz cümlesi, kural blokları yok.

## Akış
1. UI: Generate sekmesi → `_preflight` → onay sheet'i → `_generateFalAiNewFlow`
   (`pages/main_navigation_page_refactored.dart`).
2. Moderasyon: `PromptEngine.moderate` → `prompt_moderation.dart`.
   Engellenirse `prompt_issue_sheet.dart` (`blocked_prompt_dialog.dart` eski çağrılar için).
3. Prompt kurma: `PromptEngine.textToImage` / `imageToImage` / `editImage`
   (`lib/core/prompt_engine/prompt_engine.dart`) → `BuiltPrompt`.
   Stil metni `PromptItem`'dan, ortam `scene_kits.dart`'tan gelir.
4. fal çağrısı: `FalAiService` (`lib/core/services/fal_ai_service.dart`)
   - `generateImage` ~85 → `openai/gpt-image-2` (text→image)
   - `generateImageFromImage` ~153 → `openai/gpt-image-2/edit`
   - `generateVideo` ~220 → `minimax/h3-max-turbo/image-to-video` (5 sn, 768P), `buildVideoPrompt` ~209
   - kuyruk: `_runQueue` / `_runQueueRaw` ~268-380; taban URL `EnvironmentConfig.falQueueBase` (proxy veya `queue.fal.run`)
   - kalite `medium`, boyut `square` (maliyeti sabitler)
   - boş görsel listesi = fal güvenlik filtresi → `FalAiException`
5. Token düşümü: `TokenService` + `TokenCosts` (bkz MONETIZATION.md).
6. Kaydetme: `_persistGeneratedImage` → `image_storage_service.dart`, `SavedImagesProvider`;
   videolar `SavedVideosProvider`.
7. Sonuç: `generated_result_page.dart` / `video_result_page.dart`.

## Stil kütüphaneleri
- Halloween: `lib/features/home/data/services/prompt_service.dart` (aktif olan bu; `_backup/_organized/_updated` ölü)
- Christmas: `.../christmas_prompts.dart`
- Model: `.../data/models/prompt_category.dart` (`PromptItem`, iki tür: gündelik / fantastik)
- Önizleme görselleri: `lib/core/config/prompt_preview_assets.dart`
- Kullanıcı prompt'ları: `user_prompt_service.dart`
- "Surprise me" kaynağı: `widgets/prompt_suggestions.dart`
- Dokümanlar: `docs/PROMPT_LIBRARY.md` (üretilir), `docs/CHRISTMAS_PROMPT_LIBRARY.md`

## Kurallar (testlerle zorunlu)
- Kütüphane prompt metni kullanıcıya asla gösterilmez (`hidden_styles_test`, `style_copy_test`).
- Sezon başına kütüphane tamlığı: `season_completeness_test`, `christmas_library_test`, `prompt_library_test`.
- Prompt engine / moderasyon / sahne: `prompt_engine_test`, `prompt_issue_test`, `scene_kits_test`.
- fal istek gövdeleri: `fal_text_to_image_test`, `fal_image_to_video_test`, `video_mode_test`.
- Kütüphane değişince: `rm docs/PROMPT_LIBRARY.md && flutter test test/prompt_docs_test.dart`.
