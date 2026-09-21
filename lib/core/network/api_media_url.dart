import 'package:topik_go/core/network/dio_provider.dart';

const _defaultMediaCdnBaseUrl = 'https://damqug77a9y1r.cloudfront.net';
const _mediaBaseUrl = String.fromEnvironment(
  'MEDIA_BASE_URL',
  defaultValue: _defaultMediaCdnBaseUrl,
);

/// Resolves the base URL for media assets (CloudFront CDN or API server).
String get resolvedMediaBaseUrl {
  if (_mediaBaseUrl.isNotEmpty) return _mediaBaseUrl;
  return resolvedApiBaseUrl;
}

/// Turns API or CDN [url] (often `/test/audio/...` or `/media/...`) into an absolute URL for players and image views.
String resolveApiMediaUrl(String url) {
  final u = url.trim();
  if (u.isEmpty) return u;
  final lower = u.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return u;
  if (u.startsWith('//')) return 'https:$u';
  final base = resolvedMediaBaseUrl.endsWith('/')
      ? resolvedMediaBaseUrl.substring(0, resolvedMediaBaseUrl.length - 1)
      : resolvedMediaBaseUrl;
  final path = u.startsWith('/') ? u : '/$u';
  return '$base$path';
}

