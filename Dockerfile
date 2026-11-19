FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Diagnostic CLI"
LABEL org.opencontainers.image.description="DevOps Assignment 2"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       coreutils \
       hostname \
       procps \
       iputils-ping \
       iproute2 \
       mawk \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/diagnostic

COPY app/ ./app/

RUN chmod 0755 app/diagnostic.sh app/health-check.sh \
    && chown -R 10001:10001 /opt/diagnostic

USER 10001:10001

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD ["/opt/diagnostic/app/health-check.sh"]

ENTRYPOINT ["/opt/diagnostic/app/diagnostic.sh"]

CMD ["help"]
