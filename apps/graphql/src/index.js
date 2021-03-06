const express = require("express");
const { postgraphile } = require("postgraphile");
const { prod, host, port, postgraphileOptions } = require("./options");

console.info(
  `Starting GraphQL server in ${
    prod ? "Production" : "Development"
  } on ${host}:${port}`
);
const app = express();

app.use(postgraphile(process.env.DATABASE_URL, "app_public", postgraphileOptions));

app.get("/healthcheck", (req, res) => {
  res.send("Healthy!");
});

app.listen(port);
