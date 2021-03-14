import { Express, Request, Response } from "express";
import { NodePlugin } from "graphile-build";
import { Pool, PoolClient } from "pg";
import { postgraphile, PostGraphileOptions } from "postgraphile";
import { getAuthPgPool, getRootPgPool } from "./installDatabasePools";
import handleErrors from "../utils/handleErrors";

// export interface OurGraphQLContext {
//   pgClient: PoolClient;
//   sessionId: string | null;
//   rootPgPool: Pool;
//   login(user: any): Promise<void>;
//   logout(): Promise<void>;
// }

const isTest = process.env.NODE_ENV === "test";
const isDev = process.env.NODE_ENV === "development";

interface IPostGraphileOptionsOptions {
  // websocketMiddlewares?: Middleware<Request, Response>[];
  rootPgPool: Pool;
}

export function getPostGraphileOptions({
  // websocketMiddlewares,
  rootPgPool,
}: IPostGraphileOptionsOptions) {
  const options: PostGraphileOptions<Request, Response> = {
    jwtPgTypeIdentifier: "app_public.jwt_token",
    jwtSecret: process.env.JWT_SECRET_KEY,

    // This is so that PostGraphile installs the watch fixtures, it's also needed to enable live queries
    ownerConnectionString: process.env.DATABASE_URL,

    // On production we still want to start even if the database isn't available.
    // On development, we want to deal nicely with issues in the database.
    // For these reasons, we're going to keep retryOnInitFail enabled for both environments.
    retryOnInitFail: !isTest,

    // enableQueryBatching: On the client side, use something like apollo-link-batch-http to make use of this
    enableQueryBatching: true,

    // dynamicJson: instead of inputting/outputting JSON as strings, input/output raw JSON objects
    dynamicJson: true,

    // ignoreRBAC=false: honour the permissions in your DB - don't expose what you don't GRANT
    ignoreRBAC: true,

    // ignoreIndexes=false: honour your DB indexes - only expose things that are fast
    ignoreIndexes: false,

    // setofFunctionsContainNulls=false: reduces the number of nulls in your schema
    setofFunctionsContainNulls: false,

    // Enable GraphiQL in development
    graphiql: isDev || !!process.env.ENABLE_GRAPHIQL,
    // Use a fancier GraphiQL with `prettier` for formatting, and header editing.
    enhanceGraphiql: true,
    // Allow EXPLAIN in development (you can replace this with a callback function if you want more control)
    allowExplain: isDev,

    // Disable query logging - we're using morgan
    // disableQueryLog: true,

    // Custom error handling
    // @ts-ignore
    handleErrors,

    // Automatically update GraphQL schema when database changes
    watchPg: isDev,

    // Keep data/schema.graphql up to date
    sortExport: true,
    exportGqlSchemaPath: isDev ? `schema.graphql` : undefined,

    /*
     * Plugins to enhance the GraphQL schema, see:
     *   https://www.graphile.org/postgraphile/extending/
     */
    appendPlugins: [
      require("postgraphile-plugin-connection-filter"),
      require("@graphile-contrib/pg-order-by-related"),
    ],

    /*
     * Plugins we don't want in our schema
     */
    skipPlugins: [
      // Disable the 'Node' interface
      NodePlugin,
    ],

    // graphileBuildOptions: {
    //   /*
    //    * Any properties here are merged into the settings passed to each Graphile
    //    * Engine plugin - useful for configuring how the plugins operate.
    //    */
    //
    //   // Makes all SQL function arguments except those with defaults non-nullable
    //   pgStrictFunctions: true,
    // },
  };
  return options;
}

export default function installPostGraphile(app: Express) {
  const authPgPool = getAuthPgPool(app);
  const rootPgPool = getRootPgPool(app);
  const middleware = postgraphile<Request, Response>(
    authPgPool,
    "app_public",
    getPostGraphileOptions({
      rootPgPool,
    })
  );

  app.set("postgraphileMiddleware", middleware);

  app.use(middleware);
}
