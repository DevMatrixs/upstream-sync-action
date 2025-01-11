FROM alpine:3.18

WORKDIR /usr/src/app

RUN apk update && \
    apk add --no-cache \
    git \
    curl \
    bash \
    && rm -rf /var/cache/apk/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive.key | tee /etc/apt/trusted.gpg.d/githubcli.asc > /dev/null && \
    echo "https://cli.github.com/packages/alpine" >> /etc/apt/sources.list.d/github-cli.list && \
    apk update && \
    apk add gh

ENV GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}
ENV GIT_NAME=GitHub Actions
ENV GIT_EMAIL=actions@github.com

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
