import crypto from 'crypto';

// 62 alphanumeric characters (URL-safe)
const ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/**
 * Generates a cryptographically random, URL-friendly string of a specified length.
 * Default length is 7 characters.
 */
export const generateShortCode = (length: number = 7): string => {
    const bytes = crypto.randomBytes(length);
    let result = '';

    for (let i = 0; i < length; i++) {
        // Pick an index from the ALPHABET using random bytes
        const randomIndex = bytes[i] % ALPHABET.length;
        result += ALPHABET[randomIndex];
    }

    return result;
};


