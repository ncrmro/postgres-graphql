const express = require("express");
const { postgraphile } = require("postgraphile");
const { prod, host, port, postgraphileOptions } = require("./options");

console.info(
  `Starting GraphQL server in ${
    prod ? "Production" : "Development"
  } on ${host}:${port}`
);
const app = express();

app.use(postgraphile(process.env.DATABASE_URL, "public", postgraphileOptions));

app.get("/healthcheck", (req, res) => {
  res.send("Healthy!");
});

if (prod) {
  // The error handler must be before any other error middleware and after all controllers
  app.use(Sentry.Handlers.errorHandler());
}

app.listen(port);
