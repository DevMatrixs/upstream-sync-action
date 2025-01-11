FROM alpine:latest

RUN apk add --no-cache \
    bash \
    git

RUN adduser -D ci

ADD *.sh /home/ci/

RUN chmod 555 /home/ci/*.sh

# Create .gitconfig file and set correct permissions
RUN touch /home/ci/.gitconfig && chmod 666 /home/ci/.gitconfig

USER ci

ENTRYPOINT ["/home/ci/entrypoint.sh"]
