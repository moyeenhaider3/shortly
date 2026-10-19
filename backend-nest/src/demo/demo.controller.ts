// TEMPORARY: demo routes for Phase 2; deleted once real endpoints exist (see STATE.md Pending Todos)
import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { AppException } from '../common/exceptions/app.exception';
import type { Request } from 'express';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { PrismaService } from '../prisma/prisma.service';



@Controller('demo')
export class DemoController {
      constructor(private readonly prisma: PrismaService) {}   // add this

  @Get('app-exception')
  appException() {
    throw new AppException('Email is already registered', 409, 'EMAIL_ALREADY_EXISTS');
  }

  @Get('boom')
  boom() {
    // Sentinel text: proves the original message never reaches the client
    throw new Error('secret internal detail: db password is hunter2');
  }

  @Get('proto')
proto(@Req() req: Request) {
  return { protocol: req.protocol };
}
  // TEMPORARY: exercises the global ValidationPipe. Deleted in Phase 4 (the DTO stays).
  @Post('users')
  createUser(@Body() dto: CreateUserDto) {
    // Deliberately NOT returning the password.
    return { success: true, message: 'Input is valid', data: { name: dto.name, email: dto.email, role: dto.role } };
  }


    // TEMPORARY: proves global PrismaModule injection. Deleted with src/demo/ in Phase 4.
  @Get('db')
  async db() {
    const users = await this.prisma.user.count();
    const rows = await this.prisma.$queryRaw<{ ok: number }[]>`SELECT 1 AS ok`;
    return { success: true, data: { users, ok: rows[0].ok } };
  }

}
