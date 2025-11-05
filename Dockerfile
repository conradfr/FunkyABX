FROM hexpm/elixir:1.19.2-erlang-28.1.1-ubuntu-jammy-20251001
#FROM elixir:latest

ENV TZ=Europe/Paris
ENV DEBIAN_FRONTEND=noninteractive

EXPOSE 4000
EXPOSE 4001

RUN apt-get update && apt-get install --no-install-suggests -y \
    tzdata \
    build-essential make \
    imagemagick \
    pkgconf \
    libicu-dev \
    curl \
    jpegoptim optipng pngquant gifsicle \
    ffmpeg gnupg \
    inotify-tools

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
ENV NODE_MAJOR=22

# For temp forked dep
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y git libssl-dev ca-certificates nodejs

#RUN pkg-config --libs icu-uc icu-io

# Install hex package manager
RUN mix local.rebar --force
RUN mix local.hex --force

#RUN mkdir -p /app/funkyabx
COPY ./ /app/funkyabx/

WORKDIR /app/funkyabx

RUN #mv -vn config/dev.secret.exs.dist config/dev.secret.exs

# Install dependencies
RUN mix deps.get

# Compile the project
RUN mix do compile

RUN mkdir -p priv/static/uploads/
RUN mkdir -p priv/static/uploads/flac/
RUN mkdir -p priv/static/uploads/temp/

# CMD ["mix", "phx.server"]

ENTRYPOINT ["tail", "-f", "/dev/null"]