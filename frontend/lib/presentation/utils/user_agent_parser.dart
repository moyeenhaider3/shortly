/// Small, dependency-free user-agent classifier. Good enough for
/// browser / OS / device breakdowns; not a full UA database.
class ParsedUserAgent {
  final String browser;
  final String os;
  final String device;

  const ParsedUserAgent(this.browser, this.os, this.device);

  static const unknown = ParsedUserAgent('Unknown', 'Unknown', 'Unknown');
}

ParsedUserAgent parseUserAgent(String? ua) {
  if (ua == null || ua.trim().isEmpty || ua == 'Unknown') return ParsedUserAgent.unknown;
  final s = ua.toLowerCase();

  final isBot = RegExp(r'bot|crawler|spider|slurp|curl|wget|python-requests|postman|httpie|axios|node-fetch')
      .hasMatch(s);

  // Order matters: Edge and Opera include "chrome", Chrome includes "safari".
  final String browser;
  if (s.contains('postmanruntime')) {
    browser = 'Postman';
  } else if (s.startsWith('curl/')) {
    browser = 'curl';
  } else if (s.contains('edg/') || s.contains('edge/')) {
    browser = 'Edge';
  } else if (s.contains('opr/') || s.contains('opera')) {
    browser = 'Opera';
  } else if (s.contains('samsungbrowser')) {
    browser = 'Samsung Internet';
  } else if (s.contains('firefox/') || s.contains('fxios')) {
    browser = 'Firefox';
  } else if (s.contains('chrome/') || s.contains('crios')) {
    browser = 'Chrome';
  } else if (s.contains('safari/')) {
    browser = 'Safari';
  } else if (isBot) {
    browser = 'Bot';
  } else {
    browser = 'Other';
  }

  final String os;
  if (s.contains('iphone') || s.contains('ipad') || s.contains('ipod')) {
    os = 'iOS';
  } else if (s.contains('android')) {
    os = 'Android';
  } else if (s.contains('windows')) {
    os = 'Windows';
  } else if (s.contains('mac os x') || s.contains('macintosh')) {
    os = 'macOS';
  } else if (s.contains('cros')) {
    os = 'ChromeOS';
  } else if (s.contains('linux')) {
    os = 'Linux';
  } else {
    os = 'Other';
  }

  final String device;
  if (isBot) {
    device = 'Bot';
  } else if (s.contains('ipad') || (s.contains('android') && !s.contains('mobile')) || s.contains('tablet')) {
    device = 'Tablet';
  } else if (s.contains('mobi') || s.contains('iphone')) {
    device = 'Mobile';
  } else if (os == 'Other') {
    device = 'Other';
  } else {
    device = 'Desktop';
  }

  return ParsedUserAgent(browser, os, device);
}
