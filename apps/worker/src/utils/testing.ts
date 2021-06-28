import { Client as DatabaseClient } from "pg";

export async function getDatabaseClient(): Promise<DatabaseClient> {
  const client = new DatabaseClient({
    user: "postgres",
    password: "pgpass",
    database: "jtx",
    port: 5432,
    host: process.env.DATABASE_URL ? "db" : "localhost",
  });
  await client.connect();
  return client;
}
