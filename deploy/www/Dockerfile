FROM hexpm/elixir:1.13.2-erlang-24.2.1-ubuntu-bionic-20210930

RUN mkdir -p /scripts
COPY ./deploy/www/docker-entry.sh /scripts

EXPOSE 80

ARG DATABASE_URL=${DATABASE_URL}
ARG PORT=${PORT}
ARG SECRET_KEY_BASE=${SECRET_KEY_BASE}
ARG FLAC_FOLDER=${FLAC_FOLDER}
ARG TEMP_FOLDER=${TEMP_FOLDER}
ARG MIX_ENV=${MIX_ENV}
ARG TZ=${TZ}
ARG ORIGIN=${ORIGIN}
ARG HOST=${HOST}
ARG CDN_PREFIX=${CDN_PREFIX}
ARG S3_ACCESS_KEY=${S3_ACCESS_KEY}
ARG S3_SECRET_KEY=${S3_SECRET_KEY}
ARG S3_REGION=${S3_REGION}
ARG S3_HOST=${S3_HOST}
ARG MAILER_SMTP=${MAILER_SMTP}
ARG MAILER_USERNAME=${MAILER_USERNAME}
ARG MAILER_PASSWORD=${MAILER_PASSWORD}
ARG MAILER_PORT=${MAILER_PORT}
ARG EMAIL_FROM=${EMAIL_FROM}
ARG EMAIL_TO=${EMAIL_TO}

ENV DATABASE_URL=${DATABASE_URL} \
    PORT=${PORT} \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    MIX_ENV=${MIX_ENV} \
    ORIGIN=${ORIGIN} \
    HOST=${HOST} \
    FLAC_FOLDER=${FLAC_FOLDER} \
    TEMP_FOLDER=${TEMP_FOLDER} \
    TZ=${TZ} \
    CDN_PREFIX=${CDN_PREFIX} \
    S3_ACCESS_KEY=${S3_ACCESS_KEY} \
    S3_SECRET_KEY=${S3_SECRET_KEY} \
    S3_REGION=${S3_REGION} \
    S3_HOST=${S3_HOST} \
    MAILER_SMTP=${MAILER_SMTP} \
    MAILER_USERNAME=${MAILER_USERNAME} \
    MAILER_PASSWORD=${MAILER_PASSWORD} \
    MAILER_PORT=${MAILER_PORT} \
    EMAIL_FROM=${EMAIL_FROM} \
    EMAIL_TO=${EMAIL_TO}

RUN apt-get update && apt-get install --no-install-suggests -y \
    ffmpeg curl

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
    mix deps.get --only $MIX_ENV && \
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
