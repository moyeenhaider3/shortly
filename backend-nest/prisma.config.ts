import "dotenv/config"; // loads .env into process.env (the CLI no longer does this itself)
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma", // where the models live
  migrations: { path: "prisma/migrations" }, // where migration SQL is written
  datasource: {
    // process.env[...] instead of the env() helper: env() throws if DATABASE_URL is missing,
    // which would break `prisma generate` on CI or in a Docker build that has no .env.
    url: process.env["DATABASE_URL"],
  },
});
