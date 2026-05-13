import 'package:topik_go/core/network/dio_provider.dart';

String resolveMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) return trimmed;

  final base = Uri.parse(resolvedApiBaseUrl);
  return base.resolve(trimmed).toString();
}
