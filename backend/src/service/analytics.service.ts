import { Types } from 'mongoose';
import { Url } from '../models/url.model';
import { IUserDocument, UserRole } from '../models/user.model';
import { AppError } from '../middlewares/error.middleware';

export interface IRecordVisitData {
  ip?: string;
  userAgent?: string;
}

export interface IAnalyticsSummary {
  id: string;
  originalUrl: string;
  shortCode: string;
  customAlias?: string;
  totalClicks: number;
  lastVisitedAt: Date | null;
  createdAt: Date;
  recentVisits: Array<{
    visitedAt: Date;
    ip?: string;
    userAgent?: string;
  }>;
}

export class AnalyticsService {
  /**
   * Atomically records a visit and increments the total click count.
   */
  public static async recordVisit(urlId: Types.ObjectId, data: IRecordVisitData): Promise<void> {
    const visitEntry = {
      visitedAt: new Date(),
      ip: data.ip || 'Unknown',
      userAgent: data.userAgent || 'Unknown',
    };

    // Atomic update using MongoDB $inc and $push
    await Url.findByIdAndUpdate(urlId, {
      $inc: { clickCount: 1 },
      $push: { visits: visitEntry },
    });
  }

  /**
   * Retrieves analytics summary for a specific URL with RBAC ownership checks.
   */
  public static async getUrlAnalytics(
    urlId: string,
    user: IUserDocument
  ): Promise<IAnalyticsSummary> {
    if (!Types.ObjectId.isValid(urlId)) {
throw new AppError('Invalid URL ID format', 400, 'INVALID_ID');        
    }

    const url = await Url.findById(urlId);

    if (!url || !url.isActive) {
      throw new AppError('URL not found', 404, 'URL_NOT_FOUND');
    }

    // RBAC: Only the link creator OR an Admin can view analytics
    const isOwner = url.createdBy.toString() === user._id.toString();
    const isAdmin = user.role === UserRole.ADMIN;

    if (!isOwner && !isAdmin) {
      throw new AppError('You do not have permission to view analytics for this URL', 403, 'FORBIDDEN');
    }

    // Determine the most recent visit timestamp
    const lastVisitedAt = url.visits.length > 0 ? url.visits[url.visits.length - 1].visitedAt : null;

    // Return the last 10 visits for detailed inspection (sorted newest first)
    const recentVisits = [...url.visits].reverse().slice(0, 10);

    return {
      id: url._id.toString(),
      originalUrl: url.originalUrl,
      shortCode: url.shortCode,
      customAlias: url.customAlias,
      totalClicks: url.clickCount,
      lastVisitedAt,
      createdAt: url.createdAt,
      recentVisits,
    };
  }
}