import Sentry from "@sentry/node";
import { GraphQLError } from "graphql";

export default function handleErrors(errors: readonly GraphQLError[]) {
  return errors.map((error) => {
    const { message: rawMessage, locations, path, originalError } = error;
    // const code = originalError ? originalError["code"] : null;
    // const localPluck = ERROR_MESSAGE_OVERRIDES[code] || pluck;
    // const exception = localPluck(originalError || error);
    console.log(`Sentry threw an error`, error);
    // Sentry.captureException(error);
    return {
      message: rawMessage,
      locations,
      path,
      extensions: {
        exception: error,
      },
    };
  });
}
