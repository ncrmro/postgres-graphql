function handleErrors(errors) {
  return errors.map((error) => {
    const { message: rawMessage, locations, path, originalError } = error;
    // const code = originalError ? originalError["code"] : null;
    // const localPluck = ERROR_MESSAGE_OVERRIDES[code] || pluck;
    // const exception = localPluck(originalError || error);
    console.log(
      `Sentry threw and error ${process.env.RELEASE} ${process.env.ENVIRONMENT}`,
      error
    );
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

module.exports = { handleErrors };
