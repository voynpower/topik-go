import 'package:flutter_test/flutter_test.dart';
import 'package:topik_go/core/network/api_media_url.dart';
import 'package:topik_go/core/network/dio_provider.dart';

void main() {
  group('Network URL Resolution Tests', () {
    test('resolvedApiBaseUrl defaults to production backend URL', () {
      expect(resolvedApiBaseUrl, 'https://topik-api.duckdns.org');
    });

    test('resolvedMediaBaseUrl defaults to CloudFront CDN URL', () {
      expect(resolvedMediaBaseUrl, 'https://damqug77a9y1r.cloudfront.net');
    });

    test('resolveApiMediaUrl correctly handles relative paths', () {
      expect(
        resolveApiMediaUrl('/media/audio/ep60/q1.mp3'),
        'https://damqug77a9y1r.cloudfront.net/media/audio/ep60/q1.mp3',
      );
      expect(
        resolveApiMediaUrl('media/images/q5.png'),
        'https://damqug77a9y1r.cloudfront.net/media/images/q5.png',
      );
    });

    test('resolveApiMediaUrl preserves absolute URLs and protocol-relative URLs', () {
      expect(
        resolveApiMediaUrl('https://custom-cdn.com/audio.mp3'),
        'https://custom-cdn.com/audio.mp3',
      );
      expect(
        resolveApiMediaUrl('http://custom-cdn.com/audio.mp3'),
        'http://custom-cdn.com/audio.mp3',
      );
      expect(
        resolveApiMediaUrl('//custom-cdn.com/audio.mp3'),
        'https://custom-cdn.com/audio.mp3',
      );
    });

    test('resolveApiMediaUrl handles empty or whitespace-only strings', () {
      expect(resolveApiMediaUrl(''), '');
      expect(resolveApiMediaUrl('   '), '');
    });
  });
}
