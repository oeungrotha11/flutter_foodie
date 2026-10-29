import 'api_client.dart';
import '../models/food_category.dart';
import '../models/food_item.dart';
import '../models/product_option.dart';
import '../models/customer_reward.dart';
import '../models/reward_rule.dart';

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

  Future<Map<String, dynamic>> googleLogin(String firebaseIdToken) async {
    final data = await _api.post(
      '/api/v1/auth/google',
      body: {'firebaseIdToken': firebaseIdToken},
    );
    if (data is! Map ||
        data['access'] == null ||
        data['refresh'] == null ||
        data['access'].toString().trim().isEmpty ||
        data['refresh'].toString().trim().isEmpty) {
      throw const ApiException('The server returned an invalid Google login response.');
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

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _api.post(
      '/api/v1/auth/verify-email',
      body: {'email': email, 'code': code},
    );
  }

  Future<void> resendVerificationCode(String email) async {
    await _api.post(
      '/api/v1/auth/resend-verification',
      body: {'email': email},
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
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/api/v1/auth/reset-password',
      body: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }

  Future<void> setPassword({
    required String password,
    required String confirmPassword,
  }) async {
    await _api.post(
      '/api/v1/user/set-password',
      auth: true,
      body: {
        'password': password,
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

  Future<Map<String, dynamic>> updateCurrentUser({
    required String username,
    required String address,
    required String city,
    required String phone,
    required String email,
  }) async {
    final data = await _api.put(
      '/api/v1/user',
      auth: true,
      body: {
        'username': username,
        'address': address,
        'city': city,
        'phone': phone,
        'email': email,
      },
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    return {
      'username': username,
      'address': address,
      'city': city,
      'phone': phone,
      'email': email,
    };
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

  Future<List<Map<String, dynamic>>> mapAutocomplete(String input) async {
    final data = await _api.get('/api/v1/maps/autocomplete', query: {'input': input}, auth: true);
    final rows = data is Map ? data['suggestions'] : null;
    return rows is List
        ? rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> mapPlace(String placeId) async {
    final data = await _api.get('/api/v1/maps/places/${Uri.encodeComponent(placeId)}', auth: true);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The server returned an invalid place.');
  }

  Future<Map<String, dynamic>> reverseGeocode(double latitude, double longitude) async {
    final data = await _api.get('/api/v1/maps/reverse-geocode', query: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    }, auth: true);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The server returned an invalid address.');
  }

  Future<Map<String, dynamic>> deliveryRoute(double latitude, double longitude) async {
    final data = await _api.get('/api/v1/maps/route', query: {
      'destinationLatitude': latitude.toString(),
      'destinationLongitude': longitude.toString(),
    }, auth: true);
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The server returned an invalid route.');
  }

  Future<Map<String, dynamic>> deliveryAddress() async {
    final data = await _api.get('/api/v1/user/delivery-address', auth: true);
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> saveDeliveryAddress({
    required String address,
    required String city,
    required String phone,
    double? latitude,
    double? longitude,
  }) async => _api.put(
    '/api/v1/user/delivery-address',
    auth: true,
    body: {'address': address, 'city': city, 'phone': phone, if (latitude != null) 'latitude': latitude, if (longitude != null) 'longitude': longitude},
  );

  Future<dynamic> placeOrder(Map<String, dynamic> body) =>
      _api.post('/api/v1/orders', auth: true, body: body);

  Future<List<RewardRule>> rewardRules() async {
    final data = await _api.get('/api/v1/reward-rules', auth: true);
    dynamic rows = data;
    if (data is Map) {
      final envelope = data['payload'] ?? data;
      if (envelope is Map) {
        rows = envelope['content'] ??
            envelope['items'] ??
            envelope['rewardRules'] ??
            envelope['rules'] ??
            envelope['data'] ??
            (envelope.containsKey('rewardRuleId') ? [envelope] : []);
      } else {
        rows = envelope;
      }
    }
    if (rows is! List) {
      throw const ApiException('The server returned an invalid reward rule list.');
    }
    return rows
        .whereType<Map>()
        .map((row) => RewardRule.fromJson(Map<String, dynamic>.from(row)))
        .where((rule) => rule.active)
        .toList();
  }

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

  /// Checks a KHQR transaction hash through Spring Boot.
  /// This does not itself mark any Foodie order as paid.
  Future<Map<String, dynamic>> checkBakongTransaction(String md5) async {
    final data = await _api.post(
      '/api/v1/bakong/check-transaction',
      auth: true,
      body: {'md5': md5},
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('The server returned an invalid Bakong transaction response.');
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
