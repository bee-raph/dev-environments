# .NET 11 stable SDK; override DOTNET_IMAGE and EF_VERSION to pin builds.
ARG DOTNET_IMAGE=mcr.microsoft.com/dotnet/sdk:11.0
FROM node:24-bookworm-slim AS node
FROM ${DOTNET_IMAGE}

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs openssh-client bash bash-completion \
    jq ripgrep unzip zip build-essential procps less nano sqlite3 tini \
    python3-full python3-dev python3-pip python-is-python3 \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Official installer selects the current stable code-server for this architecture.
RUN curl -fsSL https://code-server.dev/install.sh -o /tmp/install-code-server.sh \
    && sh /tmp/install-code-server.sh \
    && rm /tmp/install-code-server.sh
# Official multi-architecture uv distribution, independent of system pip.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
# The Compose build supplies the shared installer as a named build context.
RUN --mount=type=bind,from=dev_common,source=install-cli-tools.sh,target=/tmp/install-cli-tools.sh \
    bash /tmp/install-cli-tools.sh

ARG DEV_UID=1000
ARG DEV_GID=1000
RUN if id ubuntu >/dev/null 2>&1; then userdel ubuntu; fi \
    && if getent group ubuntu >/dev/null; then groupdel ubuntu; fi \
    && groupadd --gid ${DEV_GID} developer \
    && useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home --shell /bin/bash developer
ENV HOME=/home/developer \
    CODEX_HOME=/home/developer/.config/codex \
    CLAUDE_CONFIG_DIR=/home/developer/.config/claude \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    GIT_CONFIG_GLOBAL=/home/developer/.config/git/config \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1 \
    DOTNET_USE_POLLING_FILE_WATCHER=1 \
    ASPNETCORE_ENVIRONMENT=Development \
    ASPNETCORE_URLS=http://0.0.0.0:5000 \
    PATH=/home/developer/.local/bin:/opt/dotnet-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ARG EF_VERSION=11.*
RUN dotnet tool install dotnet-ef --tool-path /opt/dotnet-tools --version "${EF_VERSION}" \
    && dotnet tool install dotnet-outdated-tool --tool-path /opt/dotnet-tools --allow-roll-forward \
    && mkdir -p /opt/editor-extensions /workspace/src \
       /home/developer/.local/share/code-server /home/developer/.nuget/packages \
       /home/developer/.npm /home/developer/.config \
    && mkdir -p /home/developer/.cache/pip /home/developer/.cache/uv \
    && chown -R developer:developer /home/developer /workspace /opt/editor-extensions
USER developer
RUN python --version && python3 -m pip --version && uv --version && uvx --version
# Install the native AI CLIs as developer; keep binaries outside mounted settings.
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh latest \
    && rm /tmp/install-claude.sh \
    && curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
    && CODEX_HOME=/home/developer/.local/share/codex-install sh /tmp/install-codex.sh \
    && rm /tmp/install-codex.sh \
    && claude --version && codex --version \
    && git --version && gh --version && az version && aws --version && gcloud --version && terraform version
RUN code-server --extensions-dir /opt/editor-extensions \
      --install-extension muhammad-sammy.csharp \
    && code-server --extensions-dir /opt/editor-extensions \
      --install-extension EditorConfig.EditorConfig \
    && code-server --extensions-dir /opt/editor-extensions \
      --install-extension humao.rest-client
COPY --chmod=755 entrypoint.sh /usr/local/bin/dev-entrypoint
WORKDIR /workspace/src
EXPOSE 8080 5000 5173
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
