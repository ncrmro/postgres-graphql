ARG BASE_IMAGE

FROM $BASE_IMAGE

WORKDIR /apps/database

CMD yarn migrate

COPY apps/database/package.json apps/database/yarn.lock /apps/database/

RUN yarn --frozen-lockfile

COPY apps/database/ /apps/database/
