ARG BASE_IMAGE=node:26-bookworm
FROM ${BASE_IMAGE}
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs openssh-client bash bash-completion jq ripgrep unzip zip build-essential procps less nano sqlite3 tini python3 \
    && git lfs install --system && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://code-server.dev/install.sh -o /tmp/install-code-server.sh \
    && sh /tmp/install-code-server.sh && rm /tmp/install-code-server.sh
ARG DEV_UID=1000
ARG DEV_GID=1000
RUN if id ubuntu >/dev/null 2>&1; then userdel ubuntu; fi \
    && if getent group ubuntu >/dev/null; then groupdel ubuntu; fi \
    && if id node >/dev/null 2>&1; then userdel node; fi \
    && if getent group node >/dev/null; then groupdel node; fi \
    && groupadd --gid ${DEV_GID} developer \
    && useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home --shell /bin/bash developer
ENV HOME=/home/developer \
    CODEX_HOME=/home/developer/.config/codex \
    CLAUDE_CONFIG_DIR=/home/developer/.config/claude \
    GIT_CONFIG_GLOBAL=/home/developer/.config/git/config \
    YARN_CACHE_FOLDER=/home/developer/.cache/yarn \
    PATH=/home/developer/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN npm install -g pnpm typescript ts-node eslint prettier \
    && pnpm config set --global store-dir /home/developer/.local/share/pnpm/store
RUN mkdir -p /opt/editor-extensions /workspace/src /home/developer/.local/share/code-server \
    /home/developer/.config/git /home/developer/.npm /home/developer/.local/share/pnpm/store /home/developer/.cache/yarn \
    && chown -R developer:developer /home/developer /workspace /opt/editor-extensions
USER developer
# Install the native AI CLIs as developer; keep binaries outside mounted settings.
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh stable \
    && rm /tmp/install-claude.sh \
    && curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
    && CODEX_HOME=/home/developer/.local/share/codex-install sh /tmp/install-codex.sh \
    && rm /tmp/install-codex.sh \
    && claude --version && codex --version
RUN code-server --extensions-dir /opt/editor-extensions --install-extension dbaeumer.vscode-eslint \
    && code-server --extensions-dir /opt/editor-extensions --install-extension esbenp.prettier-vscode \
    && code-server --extensions-dir /opt/editor-extensions --install-extension EditorConfig.EditorConfig \
    && code-server --extensions-dir /opt/editor-extensions --install-extension humao.rest-client
COPY --chmod=755 entrypoint.sh /usr/local/bin/dev-entrypoint
WORKDIR /workspace/src
EXPOSE 8080 8000 5173
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
