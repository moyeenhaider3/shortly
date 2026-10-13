import { Schema, model, Document, Types } from 'mongoose';

/**
 * Interface representing an individual visit log entry.
 */
export interface IVisit {
  visitedAt: Date;
  ip?: string;
  userAgent?: string;
}

export interface IUrl {
  _id: Types.ObjectId;
  originalUrl: string;
  shortCode: string;
  customAlias?: string;
  createdBy: Types.ObjectId;
  clickCount: number;
  visits: IVisit[];
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface IUrlDocument extends IUrl, Document {
  _id: Types.ObjectId;
}

/**
 * Sub-schema for individual visit entries.
 */
const visitSchema = new Schema<IVisit>(
  {
    visitedAt: {
      type: Date,
      default: Date.now,
    },
    ip: {
      type: String,
      default: 'Unknown',
    },
    userAgent: {
      type: String,
      default: 'Unknown',
    },
  },
  { _id: false }
);

const urlSchema = new Schema<IUrlDocument>(
  {
    originalUrl: {
      type: String,
      required: [true, 'Original URL is required'],
      trim: true,
    },
    shortCode: {
      type: String,
      required: [true, 'Short code is required'],
      unique: true,
      trim: true,
      index: true,
    },
    customAlias: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Created by user reference is required'],
      index: true,
    },
    clickCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    visits: [visitSchema],
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

export const Url = model<IUrlDocument>('Url', urlSchema);