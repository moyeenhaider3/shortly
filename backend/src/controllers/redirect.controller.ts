import { Request, Response, NextFunction } from 'express';
import { UrlService } from '../service/url.service';
import { AnalyticsService } from '../service/analytics.service';

export class RedirectController {
  /**
   * GET /:shortCode
   * Public redirection handler with automatic visit tracking
   */
  public static async handleRedirect(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const code = req.params.shortCode as string;
      const url = await UrlService.getUrlByShortCode(code);

      // Extract client metadata
      const ip = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || 'Unknown';
      const userAgent = req.headers['user-agent'] || 'Unknown';

      // Record the visit atomically
      await AnalyticsService.recordVisit(url._id, { ip, userAgent });

      // Perform HTTP 302 Temporary Redirect to target destination
      res.redirect(302, url.originalUrl);
    } catch (error) {
      next(error);
    }
  }
}