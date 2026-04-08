FROM debian:stable-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash coreutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN chmod +x /app/bin/shell-master /app/scripts/gen_standalone.sh

ENTRYPOINT ["/app/bin/shell-master"]
CMD ["/play"]
