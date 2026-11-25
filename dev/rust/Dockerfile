ARG BASE_IMAGE=rust:1-bookworm
FROM ${BASE_IMAGE}
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs openssh-client bash bash-completion jq ripgrep unzip zip build-essential procps less nano sqlite3 tini pkg-config libssl-dev gdb lldb \
    python3-full python3-dev python3-pip python-is-python3 \
    && git lfs install --system && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://code-server.dev/install.sh -o /tmp/install-code-server.sh \
    && sh /tmp/install-code-server.sh && rm /tmp/install-code-server.sh
# Official multi-architecture uv distribution, independent of system pip.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
# The Compose build supplies the shared installer as a named build context.
RUN --mount=type=bind,from=dev_common,source=install-cli-tools.sh,target=/tmp/install-cli-tools.sh \
    bash /tmp/install-cli-tools.sh

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
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    GIT_CONFIG_GLOBAL=/home/developer/.config/git/config \
    CARGO_HOME=/home/developer/.cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/home/developer/.local/bin:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN rustup component add rustfmt clippy rust-src rust-analyzer
RUN mkdir -p /opt/editor-extensions /workspace/src /home/developer/.local/share/code-server \
    /home/developer/.config/git /home/developer/.cargo/registry /home/developer/.cargo/git \
    && mkdir -p /home/developer/.cache/pip /home/developer/.cache/uv \
    && chown -R developer:developer /home/developer /workspace /opt/editor-extensions
RUN chown -R developer:developer /usr/local/rustup
USER developer
RUN python --version && python3 -m pip --version && uv --version && uvx --version
# Install OpenCode's native CLI alongside the other terminal coding tools.
RUN curl -fsSL https://opencode.ai/v2/install -o /tmp/install-opencode.sh \
    && bash /tmp/install-opencode.sh --no-modify-path \
    && rm /tmp/install-opencode.sh \
    && mkdir -p "$HOME/.local/bin" "$HOME/.local/share/opencode" "$HOME/.config/opencode" \
    && ln -s "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/opencode" \
    && opencode --version
# Install the native AI CLIs as developer; keep binaries outside mounted settings.
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh latest \
    && rm /tmp/install-claude.sh \
    && curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
    && CODEX_HOME=/home/developer/.local/share/codex-install sh /tmp/install-codex.sh \
    && rm /tmp/install-codex.sh \
    && claude --version && codex --version \
    && git --version && gh --version && az version && aws --version && gcloud --version && terraform version
RUN code-server --extensions-dir /opt/editor-extensions --install-extension rust-lang.rust-analyzer \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vadimcn.vscode-lldb \
    && code-server --extensions-dir /opt/editor-extensions --install-extension tamasfe.even-better-toml \
    && code-server --extensions-dir /opt/editor-extensions --install-extension EditorConfig.EditorConfig \
    && code-server --extensions-dir /opt/editor-extensions --install-extension humao.rest-client
COPY --chmod=755 entrypoint.sh /usr/local/bin/dev-entrypoint
WORKDIR /workspace/src
EXPOSE 8080 8000 5173
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
