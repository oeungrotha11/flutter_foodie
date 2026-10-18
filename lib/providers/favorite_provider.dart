import 'package:flutter/foundation.dart';
import '../services/foodie_api.dart';

class FavoriteProvider extends ChangeNotifier {
  final Set<String> _favoriteIds = {};
  Future<void>? _loadFuture;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  int get favoriteCount => _favoriteIds.length;

  bool isFavorite(String foodId) => _favoriteIds.contains(foodId);

  Future<void> load() => _loadFuture = _loadFavorites();

  Future<void> toggleFavorite(String foodId) async {
    await (_loadFuture ??= _loadFavorites());
    try {
      await FoodieApi.instance.toggleFavorite(foodId);
      if (!_favoriteIds.add(foodId)) _favoriteIds.remove(foodId);
      notifyListeners();
    } catch (_) {
      // Keep the current list unchanged when the server rejects the update.
    }
  }

  Future<void> _loadFavorites() async {
    _favoriteIds.clear();
    try {
      _favoriteIds.addAll(await FoodieApi.instance.favoriteIds());
    } catch (_) {}
    notifyListeners();
  }
}
