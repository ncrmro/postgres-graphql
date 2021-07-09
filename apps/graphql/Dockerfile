ARG BASE_IMAGE=node:12.18.2-alpine3.11

FROM $BASE_IMAGE

WORKDIR /apps/graphql

EXPOSE 5000

CMD yarn start

COPY apps/graphql/package.json apps/graphql/yarn.lock /apps/graphql/

RUN yarn install --frozen-lockfile --production=true

COPY apps/graphql/src /apps/graphql/src

COPY apps/graphql/postgraphile.tags.json5 /apps/graphql/postgraphile.tags.json5
