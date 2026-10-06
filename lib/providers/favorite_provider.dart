import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteProvider extends ChangeNotifier {
  static const _storageKey = 'pos_product.favorite_food_ids';

  final Set<String> _favoriteIds = {};
  late final Future<void> _loadFuture = _loadFavorites();

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  int get favoriteCount => _favoriteIds.length;

  bool isFavorite(String foodId) => _favoriteIds.contains(foodId);

  Future<void> load() => _loadFuture;

  Future<void> toggleFavorite(String foodId) async {
    await _loadFuture;
    if (!_favoriteIds.add(foodId)) {
      _favoriteIds.remove(foodId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _favoriteIds.toList());
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteIds.addAll(prefs.getStringList(_storageKey) ?? const []);
    notifyListeners();
  }
}
