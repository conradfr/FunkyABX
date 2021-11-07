FROM hexpm/elixir:1.12.2-erlang-24.1.4-ubuntu-bionic-20210325

RUN mkdir -p /scripts
COPY ./deploy/www/docker-entry.sh /scripts

EXPOSE 80

ARG DATABASE_URL=${DATABASE_URL}
ARG PORT=${PORT}
ARG SECRET_KEY_BASE=${SECRET_KEY_BASE}
ARG MEDIA_PATH=${MEDIA_PATH}
ARG MIX_ENV=${MIX_ENV}
ARG TZ=${TZ}
ARG ORIGIN=${ORIGIN}
ARG HOST=${HOST}
ARG CDN_PREFIX=${CDN_PREFIX}
ARG S3_ACCESS_KEY=${S3_ACCESS_KEY}
ARG S3_SECRET_KEY=${S3_SECRET_KEY}
ARG S3_REGION=${S3_REGION}
ARG S3_HOST=${S3_HOST}

ENV DATABASE_URL=${DATABASE_URL} \
    PORT=${PORT} \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    MIX_ENV=${MIX_ENV} \
    ORIGIN=${ORIGIN} \
    HOST=${HOST} \
    MEDIA_PATH=${MEDIA_PATH} \
    TZ=${TZ} \
    CDN_PREFIX=${CDN_PREFIX} \
    S3_ACCESS_KEY=${S3_ACCESS_KEY} \
    S3_SECRET_KEY=${S3_SECRET_KEY} \
    S3_REGION=${S3_REGION} \
    S3_HOST=${S3_HOST}

RUN apt-get update && apt-get install -y \
    flac curl

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash

RUN apt-get update && apt-get install -y \
    nodejs

#RUN usermod -u 1000 root
#USER www-data

RUN mkdir -p /var/funkyabx

COPY ./config/config.exs ./config/$MIX_ENV.exs /var/funkyabx/config/
#COPY  ./config /var/funkyabx/config/
#COPY  ./mix.* /var/funkyabx/
COPY ./mix.exs mix.lock /var/funkyabx/

WORKDIR /var/funkyabx/

RUN rm -Rf /var/funkyabx/_build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

COPY / /var/funkyabx/

WORKDIR /var/funkyabx/assets

RUN npm install

WORKDIR /var/funkyabx/

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
RUN mix assets.deploy

RUN mix release prod

#CMD ["_build/prod/rel/prod/bin/prod", "start"]

WORKDIR /scripts
RUN chmod +x ./docker-entry.sh
CMD ["./docker-entry.sh"]
