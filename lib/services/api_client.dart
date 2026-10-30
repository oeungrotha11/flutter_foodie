import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_token_store.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _configuredImageBaseUrl = String.fromEnvironment('IMAGE_BASE_URL');
  static const _accessKey = 'foodie.access';
  static const _refreshKey = 'foodie.refresh';

  String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  String get imageBaseUrl =>
      _configuredImageBaseUrl.isNotEmpty ? _configuredImageBaseUrl : baseUrl;

  String resolveImageUrl(String source) {
    final imageUri = Uri.tryParse(source);
    if (imageUri != null && imageUri.hasScheme) {
      final host = imageUri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
        final apiUri = Uri.parse(baseUrl);
        return imageUri.replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: imageUri.hasPort ? imageUri.port : apiUri.port,
        ).toString();
      }
      return imageUri.toString();
    }

    if (source.startsWith('/')) {
      return Uri.parse(baseUrl).resolve(source).toString();
    }

    final imageBase = imageBaseUrl.endsWith('/') ? imageBaseUrl : '$imageBaseUrl/';
    return Uri.parse(imageBase).resolve(source).toString();
  }

  Future<String?> get accessToken => SessionTokenStore.read(_accessKey);

  Future<void> saveTokens(String access, String refresh) async {
    await SessionTokenStore.write(_accessKey, access);
    await SessionTokenStore.write(_refreshKey, refresh);
  }

  Future<void> clearTokens() async {
    await SessionTokenStore.remove(_accessKey);
    await SessionTokenStore.remove(_refreshKey);
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = false}) =>
      request('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = false}) =>
      request('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = false}) =>
      request('PUT', path, body: body, auth: auth);

  Future<dynamic> request(String method, String path,
      {Map<String, String>? query, Object? body, bool auth = false,
      bool allowRefresh = true}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final response = await _send(method, uri, headers, body);
    if (response.statusCode == 401 && auth && allowRefresh && await _refresh()) {
      return request(method, path, query: query, body: body, auth: auth, allowRefresh: false);
    }
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? 'Request failed (${response.statusCode})').toString()
          : 'Request failed (${response.statusCode})';
      throw ApiException(message, statusCode: response.statusCode);
    }
    if (data is Map && data.containsKey('payload')) return data['payload'];
    return data;
  }

  Future<http.Response> _send(String method, Uri uri, Map<String, String> headers, Object? body) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'POST': return http.post(uri, headers: headers, body: encoded);
      case 'PUT': return http.put(uri, headers: headers, body: encoded);
      case 'PATCH': return http.patch(uri, headers: headers, body: encoded);
      case 'DELETE': return http.delete(uri, headers: headers, body: encoded);
      default: return http.get(uri, headers: headers);
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    if ((response.headers['content-type'] ?? '').contains('application/json')) {
      try { return jsonDecode(response.body); } catch (_) { return response.body; }
    }
    return response.body;
  }

  Future<bool> _refresh() async {
    final refresh = await SessionTokenStore.read(_refreshKey);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/v1/auth/refresh'),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refresh}));
      final result = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300 || result is! Map) {
        await clearTokens();
        return false;
      }
      final payload = result['payload'] ?? result;
      if (payload is! Map || payload['access'] == null || payload['refresh'] == null) return false;
      await saveTokens(payload['access'].toString(), payload['refresh'].toString());
      return true;
    } catch (_) { return false; }
  }
}
