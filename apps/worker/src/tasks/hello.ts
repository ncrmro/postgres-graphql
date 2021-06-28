import { Helpers } from "graphile-worker/dist";

async function hello(payload: { name: string }, helpers: Helpers) {
  const { name } = payload;
  helpers.logger.info(`Hello, ${name}`);
}

export default hello;
