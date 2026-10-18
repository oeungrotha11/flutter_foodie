import 'package:flutter/foundation.dart';
import '../models/food_category.dart';
import '../models/food_item.dart';
import '../services/foodie_api.dart';

class CatalogProvider extends ChangeNotifier {
  List<FoodItem> _products = [];
  List<FoodCategory> _categories = [FoodCategory.all];
  bool _loading = false;
  String? _error;
  List<FoodItem> get products => List.unmodifiable(_products);
  List<FoodCategory> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        FoodieApi.instance.products(),
        FoodieApi.instance.categories(),
      ]);
      _products = values[0] as List<FoodItem>;
      _categories = values[1] as List<FoodCategory>;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<FoodItem>> search(String query) =>
      FoodieApi.instance.products(search: query);
}
