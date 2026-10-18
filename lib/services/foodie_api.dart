import 'api_client.dart';
import '../models/food_category.dart';
import '../models/food_item.dart';
import '../models/product_option.dart';
import '../models/customer_reward.dart';

class FoodieApi {
  FoodieApi._();
  static final FoodieApi instance = FoodieApi._();
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _api.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    if (data is! Map ||
        data['access'] == null ||
        data['refresh'] == null ||
        data['access'].toString().trim().isEmpty ||
        data['refresh'].toString().trim().isEmpty) {
      throw const ApiException(
        'The server returned an invalid login response.',
      );
    }
    await _api.saveTokens(
      data['access'].toString().trim(),
      data['refresh'].toString().trim(),
    );
    return Map<String, dynamic>.from(data);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String confirm,
  }) async {
    await _api.post(
      '/api/v1/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'confirm': confirm,
      },
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.post(
      '/api/v1/auth/forgot-password',
      body: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/api/v1/auth/reset-password',
      body: {
        'email': email,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/api/v1/user/change-password',
      auth: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/v1/user/logout', auth: true);
    } finally {
      await _api.clearTokens();
    }
  }

  Future<Map<String, dynamic>> currentUser() async {
    final data = await _api.get('/api/v1/user/current', auth: true);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The server returned an invalid profile.');
  }

  Future<List<FoodItem>> products({String? search, String? category}) async {
    final query = <String, String>{
      'page': '1',
      'size': '100',
      'direction': 'ASC',
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      query['category'] = category;
    }
    final data = await _api.get('/api/v1/products', query: query);
    dynamic list = data;
    if (data is Map) {
      list =
          data['content'] ??
          data['items'] ??
          data['products'] ??
          data['data'] ??
          [];
    }
    if (list is! List) {
      throw const ApiException('The server returned an invalid product list.');
    }
    return list
        .whereType<Map>()
        .map((item) => FoodItem.fromApi(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<FoodCategory>> categories() async {
    final data = await _api.get('/api/v1/categories', auth: true);
    dynamic list = data;
    if (data is Map) {
      list =
          data['content'] ??
          data['items'] ??
          data['categories'] ??
          data['data'] ??
          [];
    }
    if (list is! List) {
      return const [FoodCategory.all];
    }

    final categories = <FoodCategory>[];
    for (final value in list) {
      final category = value is Map
          ? FoodCategory.fromJson(Map<String, dynamic>.from(value))
          : FoodCategory(
              categoryId: categories.length + 1,
              categoryName: value.toString(),
            );
      if (category.categoryName.trim().isNotEmpty &&
          category.categoryName.toLowerCase() != 'all') {
        categories.add(category);
      }
    }
    return [FoodCategory.all, ...categories];
  }

  Future<List<String>> favoriteIds() async {
    final data = await _api.get('/api/v1/favorites/ids', auth: true);
    dynamic ids = data;
    if (data is Map) {
      ids = data['ids'] ?? data['content'] ?? [];
    }
    return ids is List ? ids.map((id) => id.toString()).toList() : <String>[];
  }

  Future<void> toggleFavorite(String id) async =>
      _api.post('/api/v1/favorites/$id/toggle', auth: true);

  Future<List<ProductOption>> productOptions(String productId) async {
    final data = await _api.get(
      '/api/v1/products/$productId/options',
    );
    dynamic list = data;
    if (data is Map) {
      list = data['content'] ?? data['items'] ?? data['options'] ?? [];
    }
    return list is List
        ? list
              .whereType<Map>()
              .map(
                (row) => ProductOption.fromJson(Map<String, dynamic>.from(row)),
              )
              .where((option) => option.id > 0 && option.active)
              .toList()
        : <ProductOption>[];
  }

  Future<Map<String, dynamic>> deliveryAddress() async {
    final data = await _api.get('/api/v1/user/delivery-address', auth: true);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> saveDeliveryAddress({
    required String address,
    required String city,
    required String phone,
  }) async => _api.put(
    '/api/v1/user/delivery-address',
    auth: true,
    body: {'address': address, 'city': city, 'phone': phone},
  );

  Future<dynamic> placeOrder(Map<String, dynamic> body) =>
      _api.post('/api/v1/orders', auth: true, body: body);

  Future<List<CustomerReward>> rewards() async {
    final data = await _api.get('/api/v1/rewards/me', auth: true);
    dynamic rows = data;
    if (data is Map) {
      rows = data['content'] ?? data['items'] ?? data['rewards'] ?? data['data'] ?? [];
    }
    if (rows is! List) {
      throw const ApiException('The server returned an invalid reward wallet.');
    }
    return rows
        .whereType<Map>()
        .map((row) => CustomerReward.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<dynamic>> orders() async {
    final data = await _api.get(
      '/api/v1/orders',
      query: {'page': '1', 'size': '100', 'direction': 'DESC'},
      auth: true,
    );
    if (data is List) return data;
    if (data is Map) {
      final rows = data['content'] ?? data['items'] ?? data['orders'] ?? [];
      if (rows is List) return rows;
    }
    return const [];
  }
}
