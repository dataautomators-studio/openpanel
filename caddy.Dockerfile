FROM caddy:2-alpine

# Install envsubst (part of gettext)
RUN apk add --no-cache gettext

# Download op1.js directly during build
ADD https://openpanel.dev/op1.js /srv/static/op1.js

# Copy your entrypoint and template
COPY caddy.entrypoint.sh /entrypoint.sh
COPY caddy.Caddyfile.template /Caddyfile.template

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
