import { Express } from "express";
import * as Sentry from "@sentry/node";
import * as SentryTracing from "@sentry/tracing";

export default function initializeSentry(app: Express) {
  console.log("Initializing Sentry");
  Sentry.init({
    enabled: true,
    dsn:
      "https://c470634ec79645789e609dd8b4413bf4@o240145.ingest.sentry.io/5554508",
    release: process.env.RELEASE,
    environment: process.env.ENVIRONMENT,
    debug: false,

    // We recommend adjusting this value in production, or using tracesSampler
    // for finer control
    tracesSampleRate: 1.0,
    integrations: [
      new Sentry.Integrations.Http({ tracing: true }),
      new SentryTracing.Integrations.Express({
        // to trace all requests to the default router
        app,
        // alternatively, you can specify the routes you want to trace:
        // router: someRouter,
      }),
    ],
  });
  app.use(Sentry.Handlers.requestHandler());
  app.use(Sentry.Handlers.tracingHandler());
  app.get("/debug-sentry", function mainHandler(req, res) {
    throw new Error("My first Sentry error!");
  });
}
