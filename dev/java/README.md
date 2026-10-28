# Java development environment

## Tools

- Eclipse Temurin JDK 27: java, javac, JShell, Javadoc, jar and JVM diagnostics.
- Maven 3.9.16 and Gradle 9.8.1 (supports running on Java 27).
- code-server with Red Hat Java language support, Java debugger/test runner,
  Maven, Gradle, Java project manager, REST Client and EditorConfig extensions.
- Node.js 24 LTS, npm/npx for web frontend development.
- Git, Git LFS, SSH client, Bash/completion, curl, wget, jq, ripgrep,
  zip/unzip, build-essential, procps, less, nano, SQLite CLI and tini.

No database server is included. Databases can be added as separate services
later, joining this Compose project's default network.

## Launch

Start Docker with Compose, then run from this directory:

```sh
./start.sh
```

Open http://localhost:8082. All published
ports bind to localhost. This environment can run alongside the .NET container.
Copy `.env.example` to `.env` before launch to customize ports or versions.
On Linux, `start.sh` sets host UID/GID when it creates `.env`.

Host `src/` is mounted at `/workspace/src`. Clone or place projects there.
Editor settings/extensions, Git config, Maven/Gradle state and npm cache are
stored in named volumes and survive container recreation. Run as non-root.
Host credentials are not copied into the container.

## Microsoft desktop VS Code

1. Run `./start.sh`.
2. Install Microsoft VS Code and its Dev Containers extension on your host.
3. Open this `java/` directory.
4. Select **Dev Containers: Reopen in Container** from the Command Palette.

The included configuration opens `/workspace/src` in the same Compose service
and installs Java extensions through Microsoft's Marketplace. code-server
remains available independently, using Open VSX. Desktop attachment requires
VS Code on the host and is not automatically tested by the launch script.

## Develop

Use the editor terminal to compile, build, test and run your projects:

```sh
java --version
javac --version
jshell
mvn verify
# Prefer each project's wrapper when present:
./mvnw verify
./gradlew build
```

Spring Boot apps inherit `SERVER_PORT=8081` and `SERVER_ADDRESS=0.0.0.0` from
Compose. Run `./mvnw spring-boot:run` or `./gradlew bootRun` and visit
http://localhost:8081. Other frameworks must listen on `0.0.0.0:8081` too.
Framework versions and dependencies belong to the project; no global Spring
Boot CLI or application server is required for embedded-server web apps.

For Vite, use `npm run dev -- --host 0.0.0.0 --port 5173` and visit
http://localhost:5174 (host port 5174 maps to container port 5173).

For remote debugging, add this JVM option to your application:

```text
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

Host debugger port: 5005. Debugging launched directly from the Java extension
inside the container generally does not require exposing a debugger port.

Configure Git once; configuration persists in the named config volume:

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Manage

```sh
docker compose exec dev bash
docker compose logs -f dev
docker compose stop
docker compose down
# Refresh base image patches and code-server, retaining pinned Maven/Gradle:
docker compose build --pull --no-cache
./start.sh
```

`down` preserves volumes and host source. `down --volumes` deletes editor settings
and build caches, while source in `src/` remains. Customize `JAVA_IMAGE`,
`MAVEN_VERSION` and `GRADLE_VERSION` in `.env`; use compatible versions together.
For projects requiring an older JDK, change `JAVA_IMAGE` and rebuild. Project
wrappers may need an older JVM even though the installed Gradle supports JDK 27.

Sources:
- https://hub.docker.com/_/eclipse-temurin
- https://docs.gradle.org/9.8.1/release-notes.html
- https://maven.apache.org/download.cgi
- https://coder.com/docs/code-server/FAQ

## Security

Use this environment on your local machine only. Keep published ports bound
to localhost; do not expose the editor or development ports to the internet
or an untrusted network.

## AI coding CLIs

Claude Code (`claude`) and OpenAI Codex (`codex`) are installed as the non-root developer user. Run either command from your project directory in the editor terminal. Sign in separately for each environment; for Codex in a container use `codex login --device-auth`, then follow the link and code on your host browser. Run `claude` and follow its sign-in instructions.

Their settings, sessions and Linux file-based credentials live under `/home/developer/.config/claude` and `/home/developer/.config/codex` in the existing `developer-config` volume. Container replacement preserves them; `docker compose down --volumes` deletes them. Credentials are not built into images or committed to this repository.

To add the tools to an existing environment or refresh the installed versions, run `docker compose build --no-cache` followed by `./start.sh`. Claude Code installs its stable channel; Codex installs the current release. These are terminal tools available through both editors; no AI editor extensions are installed.
