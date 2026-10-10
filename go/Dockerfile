ARG BASE_IMAGE=golang:1.27-bookworm
FROM ${BASE_IMAGE}
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs openssh-client bash bash-completion jq ripgrep unzip zip build-essential procps less nano sqlite3 tini pkg-config libssl-dev gdb \
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
    GIT_CONFIG_GLOBAL=/home/developer/.config/git/config \
    GOPATH=/home/developer/go \
    GOCACHE=/home/developer/.cache/go-build \
    PATH=/opt/go-tools:/usr/local/go/bin:/home/developer/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN GOBIN=/opt/go-tools go install golang.org/x/tools/gopls@latest \
    && GOBIN=/opt/go-tools go install github.com/go-delve/delve/cmd/dlv@latest \
    && GOBIN=/opt/go-tools go install honnef.co/go/tools/cmd/staticcheck@latest
RUN mkdir -p /opt/editor-extensions /workspace/src /home/developer/.local/share/code-server \
    /home/developer/.config/git /home/developer/go/pkg/mod /home/developer/.cache/go-build \
    && chown -R developer:developer /home/developer /workspace /opt/editor-extensions
USER developer
RUN code-server --extensions-dir /opt/editor-extensions --install-extension golang.go \
    && code-server --extensions-dir /opt/editor-extensions --install-extension EditorConfig.EditorConfig \
    && code-server --extensions-dir /opt/editor-extensions --install-extension humao.rest-client
COPY --chmod=755 entrypoint.sh /usr/local/bin/dev-entrypoint
WORKDIR /workspace/src
EXPOSE 8080 8000 5173
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
