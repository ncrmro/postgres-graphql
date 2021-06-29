ARG BASE_IMAGE

FROM $BASE_IMAGE as base

WORKDIR /apps/worker

FROM base as build

COPY apps/worker/package.json apps/worker/yarn.lock /apps/worker/

RUN yarn install --frozen-lockfile

COPY apps/worker/tsconfig.json /apps/worker/

COPY apps/worker/src /apps/worker/src

RUN yarn build

FROM base as prod

CMD yarn start

COPY --from=build /apps/worker/package.json /apps/worker/yarn.lock /apps/worker/

RUN yarn install --frozen-lockfile --production=true

COPY apps/worker/crontab /apps/worker/crontab

COPY apps/worker/templates /apps/worker/templates

COPY --from=build /apps/worker/dist /apps/worker/dist

