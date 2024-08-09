#!/bin/bash

/app/encoding.sh &
/app/caddy run --config /app/Caddyfile --adapter=caddyfile
