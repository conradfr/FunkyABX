#!/bin/sh

export RELEASE_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

/var/funkyabx/_build/prod/rel/prod/bin/prod eval "FunkyABX.Release.migrate"

/var/funkyabx/_build/prod/rel/prod/bin/prod start
