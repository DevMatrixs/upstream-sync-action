FROM alpine:latest

RUN apk add --no-cache \
    bash \
    git

RUN adduser -D ci

ADD *.sh /home/ci/

RUN chmod 555 /home/ci/*.sh

RUN touch /home/ci/.gitconfig && chmod 777 /home/ci/.gitconfig

USER ci

ENTRYPOINT ["/home/ci/entrypoint.sh"]
