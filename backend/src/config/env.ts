import dotenv from 'dotenv';

dotenv.config();

interface EnvConfig {
  port: number;
  nodeEnv: string;
  mongoUri: string;
  jwtSecret: string;
  jwtExpiresIn: string;
}

export const env: EnvConfig = {
  port: Number(process.env.PORT) || 5000,
  nodeEnv: process.env.NODE_ENV || 'development',
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/url_shortener_db',
  jwtSecret: process.env.JWT_SECRET || 'fallback_secret_for_dev_only',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};