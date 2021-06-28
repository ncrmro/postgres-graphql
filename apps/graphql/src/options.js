const plugins = [
  require("postgraphile-plugin-connection-filter"),
  require("@graphile-contrib/pg-order-by-related"),
  require("@graphile-contrib/pg-many-to-many"),
  require("postgraphile/plugins").TagsFilePlugin,
];
const { handleErrors } = require("./utils");

let postgraphileOptions = {
  enableCors: true,
  exportGqlSchemaPath: "schema.graphql",
  appendPlugins: plugins,
  ignoreRBAC: false,
  jwtPgTypeIdentifier: "app_public.jwt_token",
  enableQueryBatching: true,
  legacyRelations: "omit",
};

const prod = process.env.GRAPHQL_SERVER_PRODUCTION === "true";
const port = 5000;
const host = "localhost";

if (!prod) {
  postgraphileOptions = {
    ...postgraphileOptions,
    watchPg: true,
    showErrorStack: "json",
    extendedErrors: ["hint", "detail", "errcode"],
    graphiql: true,
    enhanceGraphiql: true,
    allowExplain: true,
    jwtSecret: "test_secret",
    ownerConnectionString: process.env.ROOT_DATABASE_URL,
  };
} else {
  postgraphileOptions = {
    ...postgraphileOptions,
    handleErrors,
    graphiql: false,
    jwtSecret: process.env.JWT_SECRET_KEY,
  };
}

module.exports = { prod, host, port, postgraphileOptions };
