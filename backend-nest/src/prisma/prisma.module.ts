import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global() // exported providers become injectable everywhere, no per-module import
@Module({
  providers: [PrismaService],
  exports: [PrismaService], // still required: @Global only removes the need to import
})
export class PrismaModule {}
