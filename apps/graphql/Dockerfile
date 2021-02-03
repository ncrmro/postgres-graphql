ARG BASE_IMAGE=node:12.18.2-alpine3.11

FROM $BASE_IMAGE as base

WORKDIR /app

CMD yarn start

EXPOSE 5000

RUN apk add postgresql-client

COPY apps/graphql/package.json apps/graphql/yarn.lock /app/

RUN yarn install --production=true

COPY apps/graphql/src /app/src

FROM base as dev

RUN yarn install
