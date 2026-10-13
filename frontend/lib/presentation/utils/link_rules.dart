/// Client-side mirrors of the backend rules in
/// `backend/src/utils/validators.ts`, so users get instant feedback
/// before a request is made. The server stays the source of truth.
abstract final class LinkRules {
  static const reservedWords = {
    'api',
    'admin',
    'auth',
    'dashboard',
    'login',
    'logout',
    'signup',
    'health',
    'public',
    'static',
    'assets',
    'favicon.ico',
    'robots.txt',
    'sitemap.xml',
    'urls',
    'users',
  };

  static final _aliasPattern = RegExp(r'^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$');

  /// Returns an error message, or null when the alias format is acceptable.
  static String? aliasError(String raw) {
    final alias = raw.trim().toLowerCase();
    if (alias.isEmpty) return null;
    if (alias.length < 3) return 'Use at least 3 characters';
    if (alias.length > 30) return 'Use 30 characters or fewer';
    if (!_aliasPattern.hasMatch(alias)) return 'Letters, numbers and single hyphens only';
    if (reservedWords.contains(alias)) return '“$alias” is reserved';
    return null;
  }

  /// Returns an error message, or null when the URL is a valid http(s) URL.
  static String? urlError(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Paste a URL to shorten';
    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Enter a full URL starting with http:// or https://';
    }
    return null;
  }

  /// Adds `https://` when the user pastes a bare domain like `example.com/x`.
  static String normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty || RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)) return value;
    if (RegExp(r'^[\w-]+(\.[\w-]+)+').hasMatch(value)) return 'https://$value';
    return value;
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? emailError(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? passwordError(String? raw) {
    if (raw == null || raw.isEmpty) return 'Password is required';
    if (raw.length < 6) return 'Use at least 6 characters';
    return null;
  }
}
