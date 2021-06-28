import { run } from "graphile-worker";

async function main() {
  // Run a worker to execute jobs:
  const runner = await run({
    concurrency: 5,
    // Install signal handlers for graceful shutdown on SIGINT, SIGTERM, etc
    noHandleSignals: false,
    pollInterval: 1000,
    taskDirectory: `${__dirname}/tasks`,
    crontabFile: `${process.cwd()}/crontab`,
  });
}

main().catch((err) => {
  console.error("Worker started with error", err);
  process.exit(1);
});
