# --------------- BUILD ---------------

FROM hexpm/elixir:1.20.4-erlang-29.0.6-ubuntu-jammy-20260810 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Build-time toolchain only: the C compiler for the bcrypt/pbkdf2 NIFs and the
# Node toolchain for the asset bundle. None of it is carried into the runtime
# stage, which only needs the release and its shared libraries.
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    build-essential make \
    pkgconf \
    libssl-dev \
    git ca-certificates \
    curl gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install --no-install-recommends --no-install-suggests -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# MIX_ENV is the only variable read while compiling; it has to be set before
# `mix release`. Every other variable is read from runtime.exs at boot and lives
# in the runtime stage, where changing it cannot invalidate the dependency
# compile.
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /var/funkyabx/

RUN mix local.hex --force && mix local.rebar --force

# Dependencies first, so that editing application code does not re-download or
# recompile them.
COPY ./mix.exs ./mix.lock /var/funkyabx/

RUN mix deps.get --only prod

# deps.get does not read config, so the config copy sits below it: editing config
# then costs a recompile, not a re-download. runtime.exs is deliberately left out
# here (it arrives with the source copy below) so that touching a boot-time
# setting does not invalidate the dependency compile.
COPY ./config/config.exs ./config/${MIX_ENV}.exs /var/funkyabx/config/

RUN mix deps.compile --skip-local-deps

# Same idea for the JS dependencies: package.json / package-lock.json only.
COPY ./assets/package.json ./assets/package-lock.json /var/funkyabx/assets/

RUN npm --prefix /var/funkyabx/assets ci

COPY . /var/funkyabx/

RUN mix deps.compile

RUN mix assets.deploy

RUN mix release prod

# --------------- RUNTIME ---------------

FROM ubuntu:jammy

EXPOSE 80

ARG DEBIAN_FRONTEND=noninteractive

# ffmpeg backs the wav -> flac conversion, imagemagick backs mogrify, and the
# optimizers back the image pipeline. The release bundles its own ERTS, so no
# Erlang or Elixir toolchain is needed here.
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    tzdata \
    ca-certificates \
    libssl3 \
    imagemagick \
    ffmpeg \
    jpegoptim optipng pngquant gifsicle \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/funkyabx/

COPY --from=builder /var/funkyabx/_build/prod/rel/prod /var/funkyabx/_build/prod/rel/prod

COPY ./deploy/www/docker-entry.sh /scripts/docker-entry.sh
RUN chmod +x /scripts/docker-entry.sh

ARG DATABASE_URL=${DATABASE_URL}
ARG PORT=${PORT}
ARG SECRET_KEY_BASE=${SECRET_KEY_BASE}
ARG FLAC_FOLDER=${FLAC_FOLDER}
ARG TEMP_FOLDER=${TEMP_FOLDER}
ARG MIX_ENV=${MIX_ENV}
ARG TZ=${TZ}
ARG ORIGIN=${ORIGIN}
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
ARG ANALYTICS=${ANALYTICS}
ARG PHX_SERVER=${PHX_SERVER}
ARG PHX_HOST=${PHX_HOST}
ARG RECAPTCHA3_KEY=${RECAPTCHA3_KEY}
ARG RECAPTCHA3_SECRET=${RECAPTCHA3_SECRET}
ARG FETCHER_URL=${FETCHER_URL}
ARG FETCHER_TOKEN=${FETCHER_TOKEN}

ENV DATABASE_URL=${DATABASE_URL} \
    PORT=${PORT} \
    SECRET_KEY_BASE=${SECRET_KEY_BASE} \
    MIX_ENV=${MIX_ENV} \
    ORIGIN=${ORIGIN} \
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
    EMAIL_TO=${EMAIL_TO} \
    ANALYTICS=${ANALYTICS} \
    PHX_SERVER=${PHX_SERVER} \
    PHX_HOST=${PHX_HOST} \
    RECAPTCHA3_KEY=${RECAPTCHA3_KEY} \
    RECAPTCHA3_SECRET=${RECAPTCHA3_SECRET} \
    FETCHER_URL=${FETCHER_URL} \
    FETCHER_TOKEN=${FETCHER_TOKEN}

#RUN usermod -u 1000 root
#USER www-data

WORKDIR /scripts
CMD ["./docker-entry.sh"]
