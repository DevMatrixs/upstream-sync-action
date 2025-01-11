FROM alpine:latest

RUN apk add --no-cache \
    bash \
    git

RUN adduser -D ci

WORKDIR /home/ci

ADD entrypoint.sh /home/ci/entrypoint.sh

RUN chmod +x /home/ci/entrypoint.sh

USER ci

ENTRYPOINT ["/home/ci/entrypoint.sh"]
