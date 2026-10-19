import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client'; // generated in 03-01, NOT '@prisma/client'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  // Plain parameter (not `private readonly`): `this` can't be used before super().
  constructor(config: ConfigService) {
    super({
      adapter: new PrismaPg({ connectionString: config.getOrThrow<string>('DATABASE_URL') }),
      log: ['warn', 'error'],
    });
  }

  async onModuleInit() {
    await this.$connect(); // fail fast at boot, not on the first request
    this.logger.log('Connected to PostgreSQL'); // never log the connection string
  }

  async onModuleDestroy() {
    await this.$disconnect(); // closes the pool so the process can exit
    this.logger.log('Disconnected from PostgreSQL');
  }
}
