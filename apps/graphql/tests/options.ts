const plugins = [
  require("postgraphile-plugin-connection-filter"),
  require("@graphile-contrib/pg-order-by-related"),
];
const { handleErrors } = require("./utils/utils");

let postgraphileOptions = {
  enableCors: true,
  exportGqlSchemaPath: "schema.graphql",
  appendPlugins: plugins,
  // TODO: to use graphiql comment out the following lines:
  ignoreRBAC: false,
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
    jwtSecret: "test_secret",
    jwtPgTypeIdentifier: "public.jwt_token",
    // TODO: expiresIn is wrong key I think
    // jwtSignOptions: {
    //   expiresIn: "1y",
    // },
  };
} else {
  postgraphileOptions = {
    ...postgraphileOptions,
    handleErrors,
    graphiql: false,
    enableQueryBatching: true,
    jwtSecret: process.env.JWT_SECRET_KEY,
    jwtPgTypeIdentifier: "public.jwt_token",
  };
}

module.exports = { prod, host, port, postgraphileOptions };
