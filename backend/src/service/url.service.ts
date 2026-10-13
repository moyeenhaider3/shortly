import { Types } from 'mongoose';
import { Url, IUrlDocument } from '../models/url.model';
import { AppError } from '../middlewares/error.middleware';
import { generateShortCode } from '../utils/generateShortCode';
import { isReservedWord, isValidAliasFormat, isValidUrl } from '../utils/validators';
import { IUserDocument, UserRole } from '../models/user.model';
import { URL } from 'url';

export interface ICreateUrlInput {
    originalUrl: string;
    customAlias?: string;
}

export interface IUpdateUrlInput {
    originalUrl: string;
}

export interface IAliasAvailability{
  alias: string;
  available: boolean;
  reason?: string;
}

export class UrlService {


/**
   * Find an active URL by short code or custom alias for redirection.
   */
  public static async getUrlByShortCode(code: string): Promise<IUrlDocument> {
    const sanitizedCode = code.trim();

    // Look up URL by shortCode OR customAlias where isActive is true
    const url = await Url.findOne({
      $or: [{ shortCode: sanitizedCode }, { customAlias: sanitizedCode }],
      isActive: true,
    });

    if (!url) {
      throw new AppError('Short URL not found or has been deactivated', 404, 'URL_NOT_FOUND');
    }

    return url;
  }


  /**
   * Check whether a custom alias is available for use.
   */
public static async checkAliasAvailability(alias: string): Promise<IAliasAvailability> {
    const trimmedAlias = alias.trim().toLowerCase();

    // 1. Format check
    if (!isValidAliasFormat(trimmedAlias)) {
      return {
        alias: trimmedAlias,
        available: false,
        reason: 'Alias must be between 3 and 30 characters and contain only letters, numbers, or hyphens',
      };
    }

    // 2. Reserved word check
    if (isReservedWord(trimmedAlias)) {
      return {
        alias: trimmedAlias,
        available: false,
        reason: `'${trimmedAlias}' is a reserved system keyword and cannot be used`,
      };
    }

    // 3. Database uniqueness check
    // An alias conflicts if it already exists as a customAlias OR as a generated shortCode
    const existing = await Url.findOne({
      $or: [{ customAlias: trimmedAlias }, { shortCode: trimmedAlias }],
    });

    if (existing) {
      return {
        alias: trimmedAlias,
        available: false,
        reason: 'Custom alias is already in use',
      };
    }

    return {
      alias: trimmedAlias,
      available: true,
    };
  }


    /**
   * Create a shortened URL (supports random codes or custom aliases)
   */
  public static async createUrl(
    input: ICreateUrlInput,
    userId: Types.ObjectId
  ): Promise<IUrlDocument> {
    const { originalUrl, customAlias } = input;

    // 1. Validate original URL
    if (!originalUrl) {
      throw new AppError('Original URL is required', 400, 'ORIGINAL_URL_REQUIRED');
    }

    if (!isValidUrl(originalUrl)) {
      throw new AppError(
        'Invalid URL format. URL must start with http:// or https://',
        400,
        'INVALID_URL_FORMAT'
      );
    }

    let shortCode: string;

    // 2. Process Custom Alias if provided
    if (customAlias) {
      const sanitizedAlias = customAlias.trim().toLowerCase();

      // Run full availability validation
      const check = await this.checkAliasAvailability(sanitizedAlias);
      if (!check.available) {
        throw new AppError(check.reason || 'Alias is unavailable', 400, 'INVALID_ALIAS');
      }

      shortCode = sanitizedAlias;
    } else {
      // 3. Generate collision-resistant random short code
      let isUnique = false;
      let generatedCode = '';
      let attempts = 0;
      const MAX_ATTEMPTS = 5;

      while (!isUnique && attempts < MAX_ATTEMPTS) {
        generatedCode = generateShortCode(7);

        // Make sure generated code does not collide with a reserved word or existing record
        if (!isReservedWord(generatedCode)) {
          const existing = await Url.findOne({
            $or: [{ shortCode: generatedCode }, { customAlias: generatedCode }],
          });

          if (!existing) {
            isUnique = true;
          }
        }
        attempts++;
      }

      if (!isUnique) {
        throw new AppError(
          'Failed to generate unique short code. Please try again.',
          500,
          'CODE_GENERATION_FAILED'
        );
      }

      shortCode = generatedCode;
    }

    // 4. Save to MongoDB
    const newUrl = await Url.create({
      originalUrl,
      shortCode,
      customAlias: customAlias ? customAlias.trim().toLowerCase() : undefined,
      createdBy: userId,
      clickCount: 0,
      visits: [],
      isActive: true,
    });

    return newUrl;
  }


/**
   * Get URLs:
   * - ADMIN: returns all active URLs across the platform
   * - NORMAL: returns only URLs created by requester
   */
  public static async getUrls(user: IUserDocument): Promise<IUrlDocument[]> {
    if (user.role === UserRole.ADMIN) {
      return Url.find({ isActive: true })
        .populate('createdBy', 'name email role')
        .sort({ createdAt: -1 });
    }

    return Url.find({ createdBy: user._id, isActive: true }).sort({ createdAt: -1 });
  
}

    /**
     * Get all URLs created by a specific user
     */
    public static async getUserUrls(userId: Types.ObjectId): Promise<IUrlDocument[]> {
        return Url.find({ createdBy: userId, isActive: true }).sort({ createdAt: -1 });
    }


 /**
   * Get single URL by ID (enforcing ownership or Admin privilege)
   */
  public static async getUrlById(
    urlId: string,
    user: IUserDocument
  ): Promise<IUrlDocument> {
    if (!Types.ObjectId.isValid(urlId)) {
      throw new AppError('Invalid URL ID format', 400, 'INVALID_ID');
    }

    const url = await Url.findById(urlId);

    if (!url || !url.isActive) {
      throw new AppError('URL not found', 404, 'URL_NOT_FOUND');
    }

    const isOwner = url.createdBy.toString() === user._id.toString();
    const isAdmin = user.role === UserRole.ADMIN;

    if (!isOwner && !isAdmin) {
      throw new AppError('You do not have permission to access this resource', 403, 'FORBIDDEN');
    }

    return url;
  }

 /**
   * Update destination of an existing URL (Owner OR Admin)
   */
  public static async updateUrl(
    urlId: string,
    user: IUserDocument,
    input: IUpdateUrlInput
  ): Promise<IUrlDocument> {
    const { originalUrl } = input;

    if (!originalUrl || !isValidUrl(originalUrl)) {
      throw new AppError('Valid original URL is required', 400, 'INVALID_URL_FORMAT');
    }

    const url = await this.getUrlById(urlId, user);
    url.originalUrl = originalUrl;
    await url.save();

    return url;
  }

 /**
   * Soft-delete a URL (Owner OR Admin)
   */
  public static async deleteUrl(
    urlId: string,
    user: IUserDocument
  ): Promise<void> {
    const url = await this.getUrlById(urlId, user);
    url.isActive = false;
    await url.save();
  }


}
