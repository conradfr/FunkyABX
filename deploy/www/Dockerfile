FROM hexpm/elixir:1.16.2-erlang-26.2.5-ubuntu-jammy-20240427

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
ARG CDN_PREFIX=${CDN_PREFIX}
ARG S3_ACCESS_KEY=${S3_ACCESS_KEY}
ARG S3_SECRET_KEY=${S3_SECRET_KEY}
ARG S3_REGION=${S3_REGION}
ARG S3_HOST=${S3_HOST}
ARG MAILER_SMTP=${MAILER_SMTP}
ARG MAILER_USERNAME=${MAILER_USERNAME}
ARG MAILER_PASSWORD=${MAILER_PASSWORD}
ARG MAILER_PORT=${MAILER_PORT}
ARG SENDGRID_API_KEY=${SENDGRID_API_KEY}
ARG EMAIL_FROM=${EMAIL_FROM}
ARG EMAIL_TO=${EMAIL_TO}
ARG ANALYTICS=${ANALYTICS}
ARG DISQUS_ID=${DISQUS_ID}
ARG PHX_SERVER=${PHX_SERVER}
ARG PHX_HOST=${PHX_HOST}
ARG RECAPTCHA3_KEY=${RECAPTCHA3_KEY}
ARG RECAPTCHA3_SECRET=${RECAPTCHA3_SECRET}

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
    SENDGRID_API_KEY=${SENDGRID_API_KEY} \
    EMAIL_FROM=${EMAIL_FROM} \
    EMAIL_TO=${EMAIL_TO} \
    ANALYTICS=${ANALYTICS} \
    DISQUS_ID=${DISQUS_ID} \
    PHX_SERVER=${PHX_SERVER} \
    PHX_HOST=${PHX_HOST} \
    RECAPTCHA3_KEY=${RECAPTCHA3_KEY} \
    RECAPTCHA3_SECRET=${RECAPTCHA3_SECRET}

RUN apt-get update && apt-get install --no-install-suggests -y \
    ffmpeg curl imagemagick gnupg

RUN apt-get install --no-install-recommends --no-install-suggests -y git libssl-dev ca-certificates

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

ENV NODE_MAJOR=16

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && apt-get install -y \
    nodejs -y

#RUN usermod -u 1000 root
#USER www-data

RUN mkdir -p /var/funkyabx

COPY ./config/config.exs ./config/$MIX_ENV.exs /var/funkyabx/config/
#COPY  ./config /var/funkyabx/config/
#COPY  ./mix.* /var/funkyabx/
COPY ./mix.exs mix.lock /var/funkyabx/

WORKDIR /var/funkyabx/

#RUN rm -Rf _build && \
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get --only prod

RUN mix deps.compile --skip-local-deps

RUN mix deps.compile

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
