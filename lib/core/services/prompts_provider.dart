import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/data/models/prompt_category.dart';
import '../../features/home/data/models/user_prompt.dart';
import '../../features/home/data/services/prompt_service.dart';
import '../../features/home/data/services/user_prompt_service.dart';
import 'premium_service.dart';

class PromptsProvider extends ChangeNotifier {
  // Search state
  List<PromptItem> _searchResults = [];
  List<UserPrompt> _userPromptSearchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // User prompts state
  List<UserPrompt> _userPrompts = [];

  // Premium status
  bool _isPremium = false;
  StreamSubscription<bool>? _premiumStatusSubscription;

  // Getters
  List<PromptItem> get searchResults => List.unmodifiable(_searchResults);
  List<UserPrompt> get userPromptSearchResults =>
      List.unmodifiable(_userPromptSearchResults);
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  List<UserPrompt> get userPrompts => List.unmodifiable(_userPrompts);
  bool get isPremium => _isPremium;

  PromptsProvider() {
    _initializePremiumStatus();
    _loadFavorites();
    _loadDebugUnlock();
  }

  // Debug builds only: open every pro prompt for testing. It has no effect in
  // release builds, whatever is stored.
  static const _kDebugUnlock = 'debug_unlock_all_prompts';
  bool _debugUnlockAll = false;
  bool get debugUnlockAll => kDebugMode && _debugUnlockAll;

  Future<void> _loadDebugUnlock() async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _debugUnlockAll = prefs.getBool(_kDebugUnlock) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setDebugUnlockAll(bool value) async {
    if (!kDebugMode) return;
    _debugUnlockAll = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDebugUnlock, value);
    } catch (_) {}
  }

  // Favorites (prompt ids, oldest first), persisted locally.
  static const _kFavorites = 'favorite_prompt_ids';
  final List<String> _favoriteIds = [];
  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);
  bool isFavorite(String id) => _favoriteIds.contains(id);

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favoriteIds
        ..clear()
        ..addAll(prefs.getStringList(_kFavorites) ?? const []);
      notifyListeners();
    } catch (e) {
      debugPrint('PromptsProvider: Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (!_favoriteIds.remove(id)) _favoriteIds.add(id);
    notifyListeners(); // optimistic: UI updates immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavorites, _favoriteIds);
    } catch (e) {
      debugPrint('PromptsProvider: Error saving favorites: $e');
    }
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  // Initialize premium status and listen to changes
  Future<void> _initializePremiumStatus() async {
    try {
      final isPremium = await PremiumService.isPremiumUser();
      if (_isPremium != isPremium) {
        _isPremium = isPremium;
        notifyListeners();
      }
      _listenToPremiumStatusChanges();
    } catch (e) {
      if (_isPremium != false) {
        _isPremium = false;
        notifyListeners();
      }
    }
  }

  // Listen to premium status changes
  void _listenToPremiumStatusChanges() {
    _premiumStatusSubscription?.cancel();
    _premiumStatusSubscription = PremiumService.premiumStatusStream.listen(
      (isPremium) {
        if (_isPremium != isPremium) {
          _isPremium = isPremium;
          notifyListeners();
          debugPrint(
            'PromptsProvider: Premium status changed - isPremium: $isPremium',
          );
        }
      },
      onError: (error) {
        debugPrint(
          'PromptsProvider: Error listening to premium status: $error',
        );
      },
    );
  }

  // Load user prompts
  Future<void> loadUserPrompts() async {
    try {
      final userPrompts = await UserPromptService.getUserPrompts();
      _userPrompts = userPrompts;
      notifyListeners();
    } catch (e) {
      debugPrint('PromptsProvider: Error loading user prompts: $e');
    }
  }

  // Search functionality
  Future<void> searchPrompts(String query) async {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;

    if (_isSearching) {
      try {
        final builtInResults = PromptService.searchPrompts(query);
        final userResults = await UserPromptService.searchUserPrompts(query);

        _searchResults = builtInResults;
        _userPromptSearchResults = userResults;
        notifyListeners();
      } catch (e) {
        debugPrint('PromptsProvider: Error searching prompts: $e');
      }
    } else {
      _searchResults.clear();
      _userPromptSearchResults.clear();
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults.clear();
    _userPromptSearchResults.clear();
    notifyListeners();
  }

  // Premium prompt check
  bool isPromptPremium(PromptItem prompt) => prompt.isPremium;

  // User prompt operations
  Future<void> updateUserPromptUsage(String promptId) async {
    try {
      await UserPromptService.updatePromptUsage(promptId);
      // Reload user prompts to get updated usage count
      await loadUserPrompts();
    } catch (e) {
      debugPrint('PromptsProvider: Error updating prompt usage: $e');
    }
  }

  Future<void> deleteUserPrompt(String promptId) async {
    try {
      final success = await UserPromptService.deleteUserPrompt(promptId);
      if (success) {
        await loadUserPrompts();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PromptsProvider: Error deleting user prompt: $e');
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadUserPrompts();
  }

  // Get search results count
  int get totalSearchResults =>
      _searchResults.length + _userPromptSearchResults.length;

  /// Free users can use this many ready-made prompts per mode (text and
  /// photo); the rest need Premium. "First" follows the order the Prompts
  /// screen shows: popular first, then authoring order.
  static const int freePromptsPerMode =
      3; // text-to-image; image-to-image has 5

  /// Styles a free user cannot open, across all seasons and both modes.
  static int get lockedCountAllSeasons {
    var total = 0;
    for (final library in PromptService.allSeasonLibraries) {
      for (final type in PromptType.values) {
        total += [
          for (final c in library) ...c.prompts,
        ].where((p) => p.promptType == type && p.isPremium).length;
      }
    }
    return total;
  }

  bool isPromptLocked(PromptItem prompt) {
    if (_isPremium || debugUnlockAll) return false;
    return prompt.isPremium;
  }

  // Get popular prompts
  List<PromptItem> getPopularPrompts() {
    return PromptService.getPopularPrompts();
  }

  // Get all categories
  List<PromptCategory> getAllCategories() {
    return PromptService.getAllCategories();
  }

  // Get category content
  List<PromptItem> getCategoryContent(PromptCategory category) {
    return category.prompts;
  }
}
