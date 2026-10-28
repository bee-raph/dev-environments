# Current stable JDK major; rebuild with --pull for patch updates.
ARG JAVA_IMAGE=eclipse-temurin:27-jdk
FROM node:24-bookworm-slim AS node
FROM ${JAVA_IMAGE}

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git git-lfs openssh-client bash bash-completion \
    jq ripgrep unzip zip build-essential procps less nano sqlite3 tini \
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
ARG DEV_UID=1000
ARG DEV_GID=1000
RUN if id ubuntu >/dev/null 2>&1; then userdel ubuntu; fi \
    && if getent group ubuntu >/dev/null; then groupdel ubuntu; fi \
    && groupadd --gid ${DEV_GID} developer \
    && useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home --shell /bin/bash developer
ENV HOME=/home/developer \
    CODEX_HOME=/home/developer/.config/codex \
    CLAUDE_CONFIG_DIR=/home/developer/.config/claude \
    GIT_CONFIG_GLOBAL=/home/developer/.config/git/config \
    GRADLE_USER_HOME=/home/developer/.gradle \
    PATH=/home/developer/.local/bin:/opt/maven/bin:/opt/gradle/bin:/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ARG MAVEN_VERSION=3.9.16
ARG GRADLE_VERSION=9.8.1
RUN curl -fsSL "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && rm /tmp/maven.tar.gz /tmp/gradle.zip \
    && mkdir -p /opt/editor-extensions /workspace/src \
       /home/developer/.local/share/code-server /home/developer/.m2 \
       /home/developer/.gradle /home/developer/.npm /home/developer/.config \
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
RUN code-server --extensions-dir /opt/editor-extensions --install-extension redhat.java \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vscjava.vscode-java-debug \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vscjava.vscode-java-test \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vscjava.vscode-maven \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vscjava.vscode-gradle \
    && code-server --extensions-dir /opt/editor-extensions --install-extension vscjava.vscode-java-dependency \
    && code-server --extensions-dir /opt/editor-extensions --install-extension EditorConfig.EditorConfig \
    && code-server --extensions-dir /opt/editor-extensions --install-extension humao.rest-client
COPY --chmod=755 entrypoint.sh /usr/local/bin/dev-entrypoint
WORKDIR /workspace/src
EXPOSE 8080 8081 5173 5005
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/dev-entrypoint"]
