import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'image_storage_service.dart';

class SavedImagesProvider extends ChangeNotifier {
  List<SavedImage> _images = <SavedImage>[];
  // Small LRU: only the pictures on screen stay in memory, not the whole
  // gallery.
  static const int _cacheLimit = 24;
  final Map<String, Uint8List> _imageBytesCache = <String, Uint8List>{};
  bool _isLoading = false;

  List<SavedImage> get images => _images;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _images = await ImageStorageService.getSavedImages();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> addSavedImage({
    required Uint8List imageBytes,
    required String prompt,
    bool isImageToImage = false,
    String? originalImagePath,
    bool exportToGallery = true,
  }) async {
    await ImageStorageService.saveImage(
      imageBytes: imageBytes,
      prompt: prompt,
      isImageToImage: isImageToImage,
      originalImagePath: originalImagePath,
      exportToGallery: exportToGallery,
    );
    await load();
  }

  Future<void> deleteById(String imageId) async {
    final ok = await ImageStorageService.deleteImage(imageId);
    if (ok) {
      _imageBytesCache.remove(imageId);
      await load();
    }
  }

  Future<Uint8List?> getImageBytes(String imageId, String filePath) async {
    final cached = _imageBytesCache.remove(imageId);
    if (cached != null) {
      _imageBytesCache[imageId] = cached; // most recently used goes last
      return cached;
    }
    final bytes = await ImageStorageService.getImageBytes(filePath);
    if (bytes != null) {
      _imageBytesCache[imageId] = bytes;
      while (_imageBytesCache.length > _cacheLimit) {
        _imageBytesCache.remove(_imageBytesCache.keys.first);
      }
    }
    return bytes;
  }
}
