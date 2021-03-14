import { Express, Request, Response } from "express";
import { NodePlugin } from "graphile-build";
import { Pool, PoolClient } from "pg";
import {
  // enhanceHttpServerWithSubscriptions,
  // makePluginHook,
  // Middleware,
  postgraphile,
  PostGraphileOptions,
} from "postgraphile";
import {
  // getHttpServer,
  getWebsocketMiddlewares,
} from "../app";
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
  // @ts-ignore
  // @ts-ignore
  const options: PostGraphileOptions<Request, Response> = {
    // This is for PostGraphile server plugins: https://www.graphile.org/postgraphile/plugins/
    // pluginHook,

    // This is so that PostGraphile installs the watch fixtures, it's also needed to enable live queries
    ownerConnectionString: process.env.DATABASE_URL,

    // On production we still want to start even if the database isn't available.
    // On development, we want to deal nicely with issues in the database.
    // For these reasons, we're going to keep retryOnInitFail enabled for both environments.
    retryOnInitFail: !isTest,

    // Add websocket support to the PostGraphile server; you still need to use a subscriptions plugin such as
    // @graphile/pg-pubsub
    subscriptions: true,
    // websocketMiddlewares,

    // enableQueryBatching: On the client side, use something like apollo-link-batch-http to make use of this
    enableQueryBatching: true,

    // dynamicJson: instead of inputting/outputting JSON as strings, input/output raw JSON objects
    dynamicJson: true,

    // ignoreRBAC=false: honour the permissions in your DB - don't expose what you don't GRANT
    ignoreRBAC: false,

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
    disableQueryLog: true,

    // Custom error handling
    // @ts-ignore
    handleErrors,
    /*
     * To use the built in PostGraphile error handling, you can use the
     * following code instead of `handleErrors` above. Using `handleErrors`
     * gives you much more control (and stability) over how errors are
     * output to the user.
     */
    /*
        // See https://www.graphile.org/postgraphile/debugging/
        extendedErrors:
          isDev || isTest
            ? [
                "errcode",
                "severity",
                "detail",
                "hint",
                "positon",
                "internalPosition",
                "internalQuery",
                "where",
                "schema",
                "table",
                "column",
                "dataType",
                "constraint",
              ]
            : ["errcode"],
        showErrorStack: isDev || isTest,
        */

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

    graphileBuildOptions: {
      /*
       * Any properties here are merged into the settings passed to each Graphile
       * Engine plugin - useful for configuring how the plugins operate.
       */

      // Makes all SQL function arguments except those with defaults non-nullable
      pgStrictFunctions: true,
    },

    /*
     * Postgres transaction settings for each GraphQL query/mutation to
     * indicate to Postgres who is attempting to access the resources. These
     * will be referenced by RLS policies/triggers/etc.
     *
     * Settings set here will be set using the equivalent of `SET LOCAL`, so
     * certain things are not allowed. You can override Postgres settings such
     * as 'role' and 'search_path' here; but for settings indicating the
     * current user, session id, or other privileges to be used by RLS policies
     * the setting names must contain at least one and at most two period
     * symbols (`.`), and the first segment must not clash with any Postgres or
     * extension settings. We find `jwt.claims.*` to be a safe namespace,
     * whether or not you're using JWTs.
     */
    // async pgSettings(req) {
    //   const sessionId = uuidOrNull(req.user?.session_id);
    //   if (sessionId) {
    //     // Update the last_active timestamp (but only do it at most once every 15 seconds to avoid too much churn).
    //     await rootPgPool.query(
    //       "UPDATE app_private.sessions SET last_active = NOW() WHERE uuid = $1 AND last_active < NOW() - INTERVAL '15 seconds'",
    //       [sessionId]
    //     );
    //   }
    //   return {
    //     // Everyone uses the "visitor" role currently
    //     role: process.env.DATABASE_VISITOR,
    //
    //     /*
    //      * Note, though this says "jwt" it's not actually anything to do with
    //      * JWTs, we just know it's a safe namespace to use, and it means you
    //      * can use JWTs too, if you like, and they'll use the same settings
    //      * names reducing the amount of code you need to write.
    //      */
    //     "jwt.claims.session_id": sessionId,
    //   };
    // },

    // readReplicaPgPool ...,
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
