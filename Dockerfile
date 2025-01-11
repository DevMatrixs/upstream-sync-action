FROM alpine:3.18

WORKDIR /usr/src/app

RUN apk add --no-cache git bash

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
