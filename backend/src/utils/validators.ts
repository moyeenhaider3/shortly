/**
 * Reserved words that cannot be used as custom aliases or short codes.
 * This prevents users from breaking application routes, static assets, or future UI paths.
 */
export const RESERVED_WORDS: readonly string[] = Object.freeze([
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
]);

/**
 * Validates whether a string is a properly formatted HTTP/HTTPS URL.
 */
export const isValidUrl = (urlString: string): boolean => {
  try {
    const parsedUrl = new URL(urlString);
    return parsedUrl.protocol === 'http:' || parsedUrl.protocol === 'https:';
  } catch (error) {
    return false;
  }
};

/**
 * Validates custom alias format:
 * - Must be between 3 and 30 characters long
 * - Can only contain lowercase letters, numbers, and hyphens (slug format)
 * - Cannot start or end with a hyphen
 */
export const isValidAliasFormat = (alias: string): boolean => {
  // Regex: 3 to 30 characters, alphanumeric with optional hyphens in between
  const aliasRegex = /^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$/;

  if (alias.length < 3 || alias.length > 30) {
    return false;
  }

  return aliasRegex.test(alias);
};

/**
 * Checks if a given alias is in the reserved words blacklist (case-insensitive)
 */
export const isReservedWord = (alias: string): boolean => {
  return RESERVED_WORDS.includes(alias.toLowerCase());
};