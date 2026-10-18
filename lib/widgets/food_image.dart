import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';

Widget foodImage(String source, {BoxFit fit = BoxFit.contain}) {
  if (source.startsWith('assets/')) return Image.asset(source, fit: fit);
  if (source.isEmpty) return const Icon(Icons.fastfood, size: 56, color: Colors.black26);
  final url = ApiClient.instance.resolveImageUrl(source);
  return Image.network(url, fit: fit,
    errorBuilder: (_, error, _) {
      if (kDebugMode) debugPrint('Could not load food image $url: $error');
      return const Icon(Icons.fastfood, size: 56, color: Colors.black26);
    });
}
