ARG BASE_IMAGE

FROM $BASE_IMAGE as base

WORKDIR /apps/graphql

FROM base as dev

CMD yarn dev

FROM base as production_build

CMD yarn start

COPY apps/graphql/package.json apps/graphql/yarn.lock /apps/graphql/

RUN yarn install --frozen-lockfile --production=true

COPY apps/graphql/src /apps/graphql/src
