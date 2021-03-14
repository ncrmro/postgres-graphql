ARG BASE_IMAGE

FROM $BASE_IMAGE as base

WORKDIR /apps/database

FROM base as dev

CMD yarn dev

FROM base as production_build

CMD yarn migrate

COPY apps/database/package.json apps/database/yarn.lock /apps/database/

RUN yarn --frozen-lockfile

COPY apps/database/ /apps/database/
