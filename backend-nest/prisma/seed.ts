import 'dotenv/config'; // first: tsx does not load .env by itself
import { hash } from 'bcryptjs';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, Role } from '../src/generated/prisma/client';

// Standalone script: no Nest app, so no DI. Build the client by hand.
const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
});

async function seedUser(email: string, password: string, name: string, role: Role) {
  const passwordHash = await hash(password, 10); // bcrypt, cost 10 (same as Express)
  await prisma.user.upsert({
    where: { email },
    update: {}, // already exists -> leave it untouched (hash not rewritten)
    create: { email, name, passwordHash, role },
  });
  console.log(`Seeded ${role} ${email}`); // never log passwords or hashes
}

async function main() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Refusing to seed: NODE_ENV is production');
  }

  const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? '';
  const normalPassword = process.env.SEED_NORMAL_PASSWORD ?? '';
  if (adminPassword.length < 6 || normalPassword.length < 6) {
    throw new Error('SEED_ADMIN_PASSWORD and SEED_NORMAL_PASSWORD are required (min 6 characters)');
  }

  await seedUser(process.env.SEED_ADMIN_EMAIL ?? 'admin@example.com', adminPassword, 'Admin', Role.ADMIN);
  await seedUser(process.env.SEED_NORMAL_EMAIL ?? 'user@example.com', normalPassword, 'Normal User', Role.NORMAL);
}

main()
  .catch((err) => {
    console.error(err instanceof Error ? err.message : err);
    process.exitCode = 1; // non-zero exit so scripts/CI notice the failure
  })
  .finally(() => prisma.$disconnect()); // without this the open pool keeps the script hanging
