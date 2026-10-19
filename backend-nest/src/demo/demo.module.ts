// TEMPORARY: demo routes for Phase 2; deleted once real endpoints exist (see STATE.md Pending Todos)
import { Module } from '@nestjs/common';
import { DemoController } from './demo.controller';

@Module({
  controllers: [DemoController],
})
export class DemoModule {}
