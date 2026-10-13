import { Request, Response, NextFunction } from 'express';
import { UrlService } from '../service/url.service';
import { env } from '../config/env';
import { IUserDocument } from '../models/user.model';
import { AnalyticsService } from '../service/analytics.service';

/**
 * Helper to construct the complete short URL for client responses
 */
const formatUrlResponse = (urlDoc: any, req: Request) => {
    const protocol = req.protocol;
    const host = req.get('host'); // e.g. localhost:5000
    const shortUrl = `${protocol}://${host}/${urlDoc.shortCode}`;

  return {
    id: urlDoc._id,
    originalUrl: urlDoc.originalUrl,
    shortCode: urlDoc.shortCode,
    customAlias: urlDoc.customAlias,
    shortUrl,
    clickCount: urlDoc.clickCount,
    isActive: urlDoc.isActive,
    createdBy: urlDoc.createdBy,
    createdAt: urlDoc.createdAt,
    updatedAt: urlDoc.updatedAt,
  };
};

export class UrlController {
    /**
   * GET /api/urls/:id/analytics
   */
  public static async getUrlAnalytics(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const urlId = req.params.id as string;
      const analytics = await AnalyticsService.getUrlAnalytics(urlId, req.user!);

      res.status(200).json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/urls/check/:alias
   * Public or authenticated check for alias availability
   */
  public static async checkAlias(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const alias = req.params.alias as string;
      const result = await UrlService.checkAliasAvailability(alias);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

    /**
     * POST /api/urls
     */
    public static async createUrl(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const userId = req.user!._id;
            const url = await UrlService.createUrl(req.body, userId);

            res.status(201).json({
                success: true,
                data: formatUrlResponse(url, req),
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/urls
     */
    public static async getUserUrls(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const userId = req.user!._id;
            const urls = await UrlService.getUserUrls(userId);

            const formattedUrls = urls.map((url) => formatUrlResponse(url, req));

            res.status(200).json({
                success: true,
                count: formattedUrls.length,
                data: formattedUrls,
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * GET /api/urls/:id
     */
    public static async getUrlById(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const userId = req.user!;
            const url = await UrlService.getUrlById(req.params.id as string, userId);

            res.status(200).json({
                success: true,
                data: formatUrlResponse(url, req),
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * PATCH /api/urls/:id
     */
    public static async updateUrl(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const userId = req.user!;
            const updatedUrl = await UrlService.updateUrl(req.params.id as string, userId, req.body);

            res.status(200).json({
                success: true,
                message: 'URL updated successfully',
                data: formatUrlResponse(updatedUrl, req),
            });
        } catch (error) {
            next(error);
        }
    }

    /**
     * DELETE /api/urls/:id
     */
    public static async deleteUrl(req: Request, res: Response, next: NextFunction): Promise<void> {
        try {
            const userId = req.user!;
            await UrlService.deleteUrl(req.params.id as string, userId);

            // Section 16: 204 No Content or 200 with success message
            res.status(200).json({
                success: true,
                message: 'URL deactivated successfully',
            });
        } catch (error) {
            next(error);
        }
    }
}