import 'package:flutter_test/flutter_test.dart';
import 'package:url_shortener_client/presentation/utils/formatters.dart';
import 'package:url_shortener_client/presentation/utils/ip_mask.dart';
import 'package:url_shortener_client/presentation/utils/link_rules.dart';
import 'package:url_shortener_client/presentation/utils/user_agent_parser.dart';

void main() {
  group('LinkRules.aliasError mirrors backend validators.ts', () {
    test('accepts valid slugs', () {
      for (final ok in ['abc', 'my-link', 'Promo2026', 'a1-b2-c3', 'x' * 30]) {
        expect(LinkRules.aliasError(ok), isNull, reason: ok);
      }
    });

    test('rejects bad length, format and reserved words', () {
      expect(LinkRules.aliasError('ab'), contains('at least 3'));
      expect(LinkRules.aliasError('x' * 31), contains('30'));
      for (final bad in ['-abc', 'abc-', 'a--b', 'a_b', 'a b', 'héllo']) {
        expect(LinkRules.aliasError(bad), contains('Letters'), reason: bad);
      }
      expect(LinkRules.aliasError('Dashboard'), contains('reserved'));
      expect(LinkRules.aliasError('api'), contains('reserved'));
    });

    test('empty alias is not an error (it is optional)', () {
      expect(LinkRules.aliasError('   '), isNull);
    });
  });

  group('LinkRules URL helpers', () {
    test('urlError requires http(s) with a host', () {
      expect(LinkRules.urlError('https://example.com/a'), isNull);
      expect(LinkRules.urlError('http://localhost:3000'), isNull);
      expect(LinkRules.urlError(''), isNotNull);
      expect(LinkRules.urlError('ftp://example.com'), isNotNull);
      expect(LinkRules.urlError('not a url'), isNotNull);
    });

    test('normalizeUrl adds https:// to bare domains only', () {
      expect(LinkRules.normalizeUrl('example.com/x'), 'https://example.com/x');
      expect(LinkRules.normalizeUrl(' http://a.io '), 'http://a.io');
      expect(LinkRules.normalizeUrl('ftp://a.io'), 'ftp://a.io');
      expect(LinkRules.normalizeUrl('hello'), 'hello');
    });
  });

  group('parseUserAgent', () {
    test('desktop Chrome on macOS', () {
      final ua = parseUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0 Safari/537.36',
      );
      expect((ua.browser, ua.os, ua.device), ('Chrome', 'macOS', 'Desktop'));
    });

    test('Edge is not mistaken for Chrome', () {
      final ua = parseUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/129.0 Safari/537.36 Edg/129.0',
      );
      expect((ua.browser, ua.os, ua.device), ('Edge', 'Windows', 'Desktop'));
    });

    test('Safari on iPhone and Android tablet', () {
      final iphone = parseUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1',
      );
      expect((iphone.browser, iphone.os, iphone.device), ('Safari', 'iOS', 'Mobile'));

      final tablet = parseUserAgent(
        'Mozilla/5.0 (Linux; Android 14; SM-X710) AppleWebKit/537.36 Chrome/129.0 Safari/537.36',
      );
      expect((tablet.os, tablet.device), ('Android', 'Tablet'));
    });

    test('tools and missing values', () {
      expect(parseUserAgent('curl/8.4.0').browser, 'curl');
      expect(parseUserAgent('curl/8.4.0').device, 'Bot');
      expect(parseUserAgent('PostmanRuntime/7.39.0').browser, 'Postman');
      expect(parseUserAgent(null).browser, 'Unknown');
      expect(parseUserAgent('Unknown').os, 'Unknown');
    });
  });

  group('IP masking', () {
    test('masks IPv4, IPv4-mapped IPv6 and IPv6', () {
      expect(maskIp('203.0.113.42'), '203.0.•.•');
      expect(maskIp('::ffff:203.0.113.42'), '203.0.•.•');
      expect(maskIp('2001:db8:85a3::7334'), '2001:db8:•:•');
      expect(maskIp('::1'), '•••');
      expect(maskIp(null), 'Unknown');
    });

    test('displayIp strips the mapped prefix', () {
      expect(displayIp('::ffff:10.0.0.1'), '10.0.0.1');
    });
  });

  group('Fmt', () {
    final now = DateTime(2026, 10, 13, 12);

    test('relative', () {
      expect(Fmt.relative(now.subtract(const Duration(seconds: 10)), now: now), 'just now');
      expect(Fmt.relative(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(Fmt.relative(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(Fmt.relative(now.subtract(const Duration(days: 2)), now: now), '2d ago');
      expect(Fmt.relative(now.subtract(const Duration(days: 65)), now: now), '2mo ago');
    });

    test('age, host and count', () {
      expect(Fmt.age(now, now: now), 'Today');
      expect(Fmt.age(now.subtract(const Duration(days: 1)), now: now), '1 day');
      expect(Fmt.host('https://www.github.com/x'), 'github.com');
      expect(Fmt.stripScheme('http://localhost:5000/abc'), 'localhost:5000/abc');
      expect(Fmt.count(1284), '1,284');
      expect(Fmt.count(12500), '12.5K');
    });
  });
}
