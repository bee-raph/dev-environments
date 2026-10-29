# Both stages select the build machine's native architecture by default.
ARG SERVICE_IMAGE=mcr.microsoft.com/azure-sql-edge:latest
FROM debian:bookworm-slim AS tools
ARG TARGETARCH
ARG SQLCMD_VERSION=1.10.0
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl bzip2 \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /tools \
    && curl -fsSL "https://github.com/microsoft/go-sqlcmd/releases/download/v${SQLCMD_VERSION}/sqlcmd-linux-${TARGETARCH}.tar.bz2" -o /tmp/sqlcmd.tar.bz2 \
    && tar -xjf /tmp/sqlcmd.tar.bz2 -C /tools \
    && chmod 755 /tools/sqlcmd \
    && /tools/sqlcmd --version

FROM ${SERVICE_IMAGE}
# The base ARM64 image does not contain the ODBC-based SQL client.
COPY --from=tools /tools/sqlcmd /usr/local/bin/sqlcmd
