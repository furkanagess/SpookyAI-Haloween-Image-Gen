import 'dart:async';
import 'analytics_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../config/environment_config.dart';

class FalAiService {
  // Text to Image: OpenAI GPT Image 2 on fal.
  static const String _t2iModel = 'openai/gpt-image-2';
  static String get _t2iUrl => '${EnvironmentConfig.falQueueBase}/$_t2iModel';
  // Image to Image: OpenAI GPT Image 2 edit on fal. Takes one or more input
  // images plus an instruction; no strength, steps or negative prompt.
  static const String _i2iModel = 'openai/gpt-image-2/edit';
  static String get _i2iUrl => '${EnvironmentConfig.falQueueBase}/$_i2iModel';

  /// Both image models run at medium quality and the 512x512 preset
  /// (`square`). Quality and size drive cost; fixing them keeps it flat.
  static const String imageQuality = 'medium';
  static const String imageSize = 'square';

  /// Kept for the image-to-image call sites and tests.
  static const String i2iQuality = imageQuality;
  static const String i2iImageSize = imageSize;

  // Image to Video: MiniMax H3 Max on fal (~$0.60 per 5 s 1080P clip).
  static const String _i2vModel = 'minimax/h3-max/image-to-video';
  static String get _i2vUrl => '${EnvironmentConfig.falQueueBase}/$_i2vModel';

  /// Fixed clip length and resolution keep the cost per video predictable.
  static const int videoSeconds = 5;
  static const String videoResolution = '1080P';

  /// HTTP client for text-to-image; replaceable in tests.
  static http.Client httpClient = http.Client();

  static void _debugPrompt(String mode, String prompt) {
    if (!kDebugMode) return;
    stdout.writeln('\n========== FAL.AI $mode PROMPT ==========');
    stdout.writeln(prompt);
    stdout.writeln('========== END FAL.AI PROMPT ==========\n');
  }

  /// Auth headers for the active mode (direct key or proxy token).
  static Map<String, String> _auth() {
    try {
      return EnvironmentConfig.falAuthHeaders();
    } on StateError catch (e) {
      throw FalAiException('FAL_AI_API_KEY not configured: ${e.message}');
    }
  }

  /// Request body for GPT Image 2 text-to-image. Pure and testable.
  ///
  /// Always medium quality, the 512x512 `square` preset and one image, so a
  /// generation costs the same every time. Safety checking stays on.
  @visibleForTesting
  static Map<String, dynamic> buildTextToImageBody({
    required String prompt,
    String outputFormat = 'jpeg',
  }) {
    final format = const {'jpeg', 'png', 'webp'}.contains(outputFormat)
        ? outputFormat
        : 'jpeg';
    return {
      'prompt': prompt,
      'image_size': imageSize,
      'quality': imageQuality,
      'num_images': 1,
      'output_format': format,
      if (format != 'png') 'output_compression': 90,
      'background': 'opaque',
      'enable_safety_checker': true,
    };
  }

  /// Text to Image with GPT Image 2.
  ///
  /// [prompt] is the final prompt from `PromptEngine.textToImage`. The model
  /// takes no negative prompt, so constraints are worded positively inside it.
  static Future<FalAiResult> generateImage({
    required String prompt,
    String outputFormat = 'jpeg',
    bool Function()? isCancelled,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      final String text = prompt.trim();
      if (text.length < 3) {
        throw FalAiException('Prompt cannot be empty');
      }
      _debugPrompt('text-to-image', text);
      final json = await _runQueue(
        _t2iUrl,
        buildTextToImageBody(prompt: text, outputFormat: outputFormat),
        isCancelled: isCancelled,
        timeout: timeout,
      );
      return _parseResult(json, text);
    } catch (e) {
      if (e is FalAiException) rethrow;
      throw FalAiException('Error generating image: $e');
    }
  }

  /// Request body for GPT Image 2 edit. Pure and testable.
  ///
  /// The photo travels as a base64 data URI in `image_urls`. Safety checking
  /// stays on, the output size is fixed and one image is requested, so a
  /// generation always costs the same.
  @visibleForTesting
  static Map<String, dynamic> buildImageToImageBody({
    required String prompt,
    required String imageDataUri,
    String imageSize = i2iImageSize,
    String quality = i2iQuality,
    String outputFormat = 'jpeg',
  }) {
    const sizes = {
      'square_hd',
      'square',
      'portrait_4_3',
      'portrait_16_9',
      'landscape_4_3',
      'landscape_16_9',
      'auto',
    };
    final format = const {'jpeg', 'png', 'webp'}.contains(outputFormat)
        ? outputFormat
        : 'jpeg';
    return {
      'prompt': prompt,
      'image_urls': [imageDataUri],
      'image_size': sizes.contains(imageSize) ? imageSize : i2iImageSize,
      'quality': const {'low', 'medium', 'high'}.contains(quality)
          ? quality
          : i2iQuality,
      'num_images': 1,
      'output_format': format,
      if (format != 'png') 'output_compression': 90,
      'background': 'opaque',
      'enable_safety_checker': true,
    };
  }

  /// Image to Image with GPT Image 2 edit.
  ///
  /// [prompt] is the final prompt from `PromptEngine.imageToImage`.
  static Future<FalAiResult> generateImageFromImage({
    required String prompt,
    required Uint8List imageBytes,
    String quality = i2iQuality,
    String imageSize = i2iImageSize,
    String outputFormat = 'jpeg',
    bool Function()? isCancelled,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    try {
      final String text = prompt.trim();
      if (text.isEmpty) {
        throw FalAiException('Prompt cannot be empty');
      }
      final dataUri =
          'data:${_detectMimeType(imageBytes)};base64,${base64Encode(imageBytes)}';
      _debugPrompt('image-to-image', text);
      final json = await _runQueue(
        _i2iUrl,
        buildImageToImageBody(
          prompt: text,
          imageDataUri: dataUri,
          imageSize: imageSize,
          quality: quality,
          outputFormat: outputFormat,
        ),
        isCancelled: isCancelled,
        timeout: timeout,
      );
      return _parseResult(json, text);
    } catch (e) {
      if (e is FalAiException) rethrow;
      throw FalAiException('Error generating image from image: $e');
    }
  }

  /// Request body for the image-to-video model. Pure and testable.
  @visibleForTesting
  static Map<String, dynamic> buildImageToVideoBody({
    required String imageDataUri,
    required String prompt,
    int? seed,
  }) => {
    'prompt': prompt,
    'image_url': imageDataUri,
    'duration': videoSeconds,
    'resolution': videoResolution,
    // fal expands the prompt for quality; our no-speech line goes along.
    'prompt_expansion_mode': 'quality',
    'enable_safety_checker': true,
    if (seed != null) 'seed': seed,
  };

  /// Motion prompt sent to the video model: the user's motion (or a gentle
  /// default) plus one short face sentence. The user's text is framed as a
  /// scene direction and speech is ruled out, so the model acts it out
  /// instead of reading it aloud. Pure and testable.
  @visibleForTesting
  static String buildVideoPrompt(String? motionPrompt) {
    final extra = (motionPrompt ?? '').trim().replaceAll(
      RegExp(r'[,.;:!\s]+$'),
      '',
    );
    final action = extra.isEmpty ? 'Subtle, natural motion' : 'Action: $extra';
    return '$action. Keep the same face, natural and true to the photo, and keep the scene, lighting and setting from the image. $_noSpeech';
  }

  static const String _noSpeech =
      'No speech, voiceover or narration; ambient sound only.';

  /// Animates a generated image. Returns the CDN URL of the mp4.
  static Future<String> generateVideo({
    required Uint8List imageBytes,
    String? motionPrompt,
    bool Function()? isCancelled,
    Duration timeout = const Duration(minutes: 6),
  }) async {
    try {
      final continuityPrompt = buildVideoPrompt(motionPrompt);
      _debugPrompt('image-to-video', continuityPrompt);
      final dataUri =
          'data:${_detectMimeType(imageBytes)};base64,${base64Encode(imageBytes)}';
      final json = await _runQueue(
        _i2vUrl,
        buildImageToVideoBody(imageDataUri: dataUri, prompt: continuityPrompt),
        isCancelled: isCancelled,
        timeout: timeout,
      );
      final video = json['video'];
      final url = video is Map ? video['url'] as String? : null;
      if (url == null || url.isEmpty) {
        throw FalAiException(
          'Generation returned no video (filtered by the safety system)',
        );
      }
      return url;
    } catch (e) {
      if (e is FalAiException) rethrow;
      throw FalAiException('Error generating video: $e');
    }
  }

  /// Downloads a finished video; the fal key is not sent to the CDN.
  /// Storing it is the caller's job (SavedVideosProvider keeps it inside
  /// the app, like pictures).
  static Future<Uint8List> downloadVideoBytes(String videoUrl) async {
    final response = await http.get(Uri.parse(videoUrl));
    if (response.statusCode != 200) {
      throw FalAiException('Failed to download video: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  /// Poll interval for queue requests; shortened in tests.
  @visibleForTesting
  static Duration pollInterval = const Duration(milliseconds: 1500);

  /// Submit → poll → fetch result for any fal queue endpoint.
  /// Runs a fal queue job and records the outcome in the analytics funnel.
  static Future<Map<String, dynamic>> _runQueue(
    String url,
    Map<String, dynamic> body, {
    bool Function()? isCancelled,
    required Duration timeout,
  }) async {
    final kind = url.contains('video') ? 'video' : 'image';
    try {
      final json = await _runQueueRaw(
        url,
        body,
        isCancelled: isCancelled,
        timeout: timeout,
      );
      unawaited(AnalyticsService.generation(kind: kind, success: true));
      return json;
    } catch (e, st) {
      if (!(isCancelled?.call() ?? false)) {
        unawaited(AnalyticsService.generation(kind: kind, success: false));
        unawaited(AnalyticsService.recordError(e, st, reason: 'fal $kind'));
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _runQueueRaw(
    String url,
    Map<String, dynamic> body, {
    bool Function()? isCancelled,
    required Duration timeout,
  }) async {
    final headers = {
      ..._auth(),
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final submit = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    if (submit.statusCode ~/ 100 != 2) {
      throw FalAiException(
        'Failed to submit generation: ${submit.statusCode} - ${submit.body}',
      );
    }

    final Map<String, dynamic> submitted = submit.body.isEmpty
        ? {}
        : jsonDecode(submit.body) as Map<String, dynamic>;

    // Defensive: some responses are already the result.
    if (submitted.containsKey('images')) return submitted;

    final String? requestId = submitted['request_id'] as String?;
    final String statusUrl =
        (submitted['status_url'] as String?) ??
        (requestId != null ? '$url/requests/$requestId/status' : '');
    final String resultUrl =
        (submitted['response_url'] as String?) ??
        (requestId != null ? '$url/requests/$requestId' : '');
    if (statusUrl.isEmpty || resultUrl.isEmpty) {
      throw FalAiException('No request_id or URLs provided by server');
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isCancelled != null && isCancelled()) {
        throw FalAiException('Generation cancelled by user');
      }
      await Future<void>.delayed(pollInterval);

      final st = await httpClient.get(Uri.parse(statusUrl), headers: _auth());
      if (st.statusCode ~/ 100 != 2) {
        throw FalAiException(
          'Failed to get status: ${st.statusCode} - ${st.body}',
        );
      }
      final status =
          (jsonDecode(st.body) as Map<String, dynamic>)['status'] as String?;

      if (status == 'COMPLETED') {
        final res = await httpClient.get(
          Uri.parse(resultUrl),
          headers: _auth(),
        );
        if (res.statusCode ~/ 100 != 2) {
          throw FalAiException(
            'Failed to get result: ${res.statusCode} - ${res.body}',
          );
        }
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (status == 'FAILED' || status == 'ERROR') {
        throw FalAiException('Generation failed: ${st.body}');
      }
      // IN_QUEUE / IN_PROGRESS: keep polling.
    }

    throw FalAiException('Generation timeout - took too long');
  }

  static FalAiResult _parseResult(Map<String, dynamic> json, String prompt) {
    final result = FalAiResult.fromJson({...json, 'prompt': prompt});
    if (result.images.isEmpty) {
      // Both models return an empty image list when their own safety system
      // declines a request.
      throw FalAiException(
        'Generation returned no image (filtered by the safety system)',
      );
    }
    return result;
  }

  /// Fetch image bytes directly from URL (no saving, for immediate display)
  static Future<Uint8List> fetchImageBytes(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final headers = _auth();

      // Use authorized request first to support short-lived signed URLs
      http.Response response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        // Retry without auth if the endpoint rejects headers (public CDN)
        response = await http.get(uri);
      }
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw FalAiException(
        'Failed to fetch image bytes: ${response.statusCode}',
      );
    } catch (e) {
      throw FalAiException('Error fetching image bytes: $e');
    }
  }

  /// Detect MIME type from image bytes
  static String _detectMimeType(Uint8List imageBytes) {
    if (imageBytes.length < 4) return 'image/jpeg';

    // Check for PNG signature
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      return 'image/png';
    }

    // Check for JPEG signature
    if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
      return 'image/jpeg';
    }

    // Check for WebP signature
    if (imageBytes.length >= 12 &&
        imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      return 'image/webp';
    }

    // Default to JPEG if we can't detect
    return 'image/jpeg';
  }

  /// Download and save image to device
  static Future<String> downloadAndSaveImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final headers = _auth();

      // Fetch with auth first (handles private URLs)
      http.Response response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        response = await http.get(uri);
      }
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'fal_ai_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // Best-effort gallery save: do not fail overall flow if this errors
        try {
          await Gal.putImage(file.path);
          unawaited(AnalyticsService.imageSaved());
        } catch (_) {}

        return file.path;
      } else {
        throw FalAiException(
          'Failed to download image: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw FalAiException('Error downloading image: $e');
    }
  }
}

class FalAiResult {
  final List<FalAiImage> images;
  final String prompt;
  final Map<String, dynamic>? metadata;

  FalAiResult({required this.images, required this.prompt, this.metadata});

  factory FalAiResult.fromJson(Map<String, dynamic> json) {
    debugPrint('🎃 FAL: Parsing result JSON: ${json.keys}');

    // Handle different response formats
    List<dynamic> imagesList = [];

    if (json.containsKey('images')) {
      imagesList = json['images'] as List;
      debugPrint('🎃 FAL: Found images in response: ${imagesList.length}');
    } else if (json.containsKey('output')) {
      imagesList = json['output'] as List;
      debugPrint('🎃 FAL: Found output in response: ${imagesList.length}');
    } else if (json.containsKey('data') && json['data'] is Map) {
      final data = json['data'] as Map;
      if (data.containsKey('images')) {
        imagesList = data['images'] as List? ?? [];
        debugPrint('🎃 FAL: Found images in data: ${imagesList.length}');
      } else if (data.containsKey('output')) {
        imagesList = data['output'] as List? ?? [];
        debugPrint('🎃 FAL: Found output in data: ${imagesList.length}');
      } else {
        debugPrint('🎃 FAL: No images found in data');
        imagesList = [];
      }
    } else {
      debugPrint('🎃 FAL: No images found in response');
      imagesList = [];
    }

    if (imagesList.isEmpty) {
      debugPrint('🎃 FAL: WARNING - No images in response!');
      debugPrint('🎃 FAL: Full response: $json');
    }

    return FalAiResult(
      images: imagesList
          .map(
            (image) => FalAiImage.fromJson(
              image is String ? {'url': image} : image as Map<String, dynamic>,
            ),
          )
          .toList(),
      prompt: json['prompt'] ?? '',
      metadata: json['metadata'],
    );
  }

  /// FLUX Schnell specific response parsing
  static Future<FalAiResult> fromFluxSchnellJson(
    Map<String, dynamic> json,
    String prompt,
  ) async {
    debugPrint('🎃 FLUX: Parsing FLUX Schnell response');
    debugPrint('🎃 FLUX: Response keys: ${json.keys.toList()}');

    // FLUX Schnell response structure is different
    List<Map<String, dynamic>> images = [];

    // Format 1: Direct images array
    if (json.containsKey('images') && json['images'] is List) {
      final imagesList = json['images'] as List;
      debugPrint('🎃 FLUX: Found images array with ${imagesList.length} items');

      for (final imageData in imagesList) {
        if (imageData is Map<String, dynamic>) {
          images.add(imageData);
        }
      }
    }
    // Format 2: Nested in data/images
    else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data.containsKey('images') && data['images'] is List) {
        final imagesList = data['images'] as List;
        debugPrint(
          '🎃 FLUX: Found nested images array with ${imagesList.length} items',
        );

        for (final imageData in imagesList) {
          if (imageData is Map<String, dynamic>) {
            images.add(imageData);
          }
        }
      }
    }
    // Format 3: Single image in data
    else if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data.containsKey('url') || data.containsKey('image_url')) {
        debugPrint('🎃 FLUX: Found single image in data');
        images.add(data);
      }
    }
    // Format 4: Direct URL fields
    else if (json.containsKey('url')) {
      debugPrint('🎃 FLUX: Found direct URL field');
      images.add({
        'url': json['url'],
        'content_type': json['content_type'] ?? 'image/jpeg',
      });
    } else if (json.containsKey('image_url')) {
      debugPrint('🎃 FLUX: Found direct image_url field');
      images.add({
        'url': json['image_url'],
        'content_type': json['content_type'] ?? 'image/jpeg',
      });
    }
    // Format 5: Response URL that needs to be fetched
    else if (json.containsKey('response_url')) {
      debugPrint('🎃 FLUX: Found response_url, fetching actual result...');
      final responseUrl = json['response_url'] as String;

      try {
        // Fetch the actual result from response_url
        final response = await http.get(
          Uri.parse(responseUrl),
          headers: FalAiService._auth(),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          debugPrint(
            '🎃 FLUX: Response URL data: ${responseData.keys.toList()}',
          );

          // Recursively parse the response
          final nestedResult = await FalAiResult.fromFluxSchnellJson(
            responseData,
            prompt,
          );
          return nestedResult;
        } else {
          debugPrint(
            '🎃 FLUX: Failed to fetch response_url: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('🎃 FLUX: Error fetching response_url: $e');
      }
    }

    debugPrint('🎃 FLUX: Parsed ${images.length} images');

    if (images.isEmpty) {
      debugPrint('🎃 FLUX: No images found in response');
      debugPrint('🎃 FLUX: WARNING - No images in response!');
      debugPrint('🎃 FLUX: Full response: $json');

      // Try to find any URL-like fields in the response
      final allKeys = json.keys.toList();
      debugPrint('🎃 FLUX: Available keys: $allKeys');

      // Look for any field that might contain a URL
      for (final key in allKeys) {
        final value = json[key];
        if (value is String &&
            (value.startsWith('http') || value.startsWith('https'))) {
          debugPrint('🎃 FLUX: Found potential URL in field $key: $value');
          images.add({'url': value, 'content_type': 'image/jpeg'});
          break;
        }
      }
    }

    if (images.isEmpty) {
      throw FalAiException(
        'No images found in FLUX Schnell response. '
        'Response structure: ${json.keys.toList()}',
      );
    }

    // Convert to FalAiImage objects
    final falImages = images.map((imageData) {
      final url =
          imageData['url'] as String? ??
          imageData['image_url'] as String? ??
          imageData['src'] as String?;

      if (url == null) {
        throw FalAiException('No URL found in image data: $imageData');
      }

      return FalAiImage(
        url: url,
        contentType:
            imageData['content_type'] as String? ??
            imageData['contentType'] as String? ??
            'image/jpeg',
      );
    }).toList();

    return FalAiResult(
      images: falImages,
      prompt: prompt,
      metadata: {
        'model': 'fal-ai/flux/schnell',
        'response_format': 'flux_schnell',
        'parsed_images': images.length,
      },
    );
  }
}

class FalAiImage {
  final String url;
  final String contentType;
  final int? width;
  final int? height;

  FalAiImage({
    required this.url,
    required this.contentType,
    this.width,
    this.height,
  });

  factory FalAiImage.fromJson(Map<String, dynamic> json) {
    debugPrint('🎃 FAL: Parsing image JSON: ${json.keys}');

    String resolvedUrl = '';
    if (json['url'] is String) {
      resolvedUrl = json['url'] as String;
      debugPrint('🎃 FAL: Found URL: $resolvedUrl');
    } else if (json['image'] is String) {
      resolvedUrl = json['image'] as String;
      debugPrint('🎃 FAL: Found image string: $resolvedUrl');
    } else if (json['image'] is Map) {
      final imageMap = json['image'] as Map;
      if (imageMap['url'] is String) {
        resolvedUrl = imageMap['url'] as String;
        debugPrint('🎃 FAL: Found URL in image map: $resolvedUrl');
      }
    }

    if (resolvedUrl.isEmpty) {
      debugPrint('🎃 FAL: WARNING - No URL found in image data!');
      debugPrint('🎃 FAL: Image JSON: $json');
    }

    String resolvedContentType = 'image/png';
    if (json['content_type'] is String) {
      resolvedContentType = json['content_type'] as String;
    } else if (json['mime'] is String) {
      resolvedContentType = json['mime'] as String;
    }

    return FalAiImage(
      url: resolvedUrl,
      contentType: resolvedContentType,
      width: json['width'],
      height: json['height'],
    );
  }
}

class FalAiException implements Exception {
  final String message;

  FalAiException(this.message);

  @override
  String toString() => 'FalAiException: $message';
}
