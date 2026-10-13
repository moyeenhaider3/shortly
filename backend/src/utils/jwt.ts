import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';

/**
 * Shape of the payload encoded inside the JWT
 */
export interface ITokenPayload {
  userId: string;
}

/**
 * Generates a signed JWT for an authenticated user
 */
export const signToken = (payload: ITokenPayload): string => {
  const options: SignOptions = {
    expiresIn: env.jwtExpiresIn as any,
  };

  return jwt.sign(payload, env.jwtSecret, options);
};

/**
 * Verifies the validity and signature of a JWT
 */
export const verifyToken = (token: string): ITokenPayload => {
  return jwt.verify(token, env.jwtSecret) as ITokenPayload;
};