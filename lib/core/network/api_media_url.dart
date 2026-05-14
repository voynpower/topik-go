import 'package:topik_go/core/network/dio_provider.dart';

/// Turns API [url] (often `/test/audio/...`) into an absolute URL for the player.
String resolveApiMediaUrl(String url) {
  final u = url.trim();
  if (u.isEmpty) return u;
  final lower = u.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return u;
  if (u.startsWith('//')) return 'https:$u';
  final base = resolvedApiBaseUrl.endsWith('/')
      ? resolvedApiBaseUrl.substring(0, resolvedApiBaseUrl.length - 1)
      : resolvedApiBaseUrl;
  final path = u.startsWith('/') ? u : '/$u';
  return '$base$path';
}
