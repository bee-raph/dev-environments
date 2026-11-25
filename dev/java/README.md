# Java development environment

## Tools and defaults

Eclipse Temurin JDK 27, javac, JShell, Javadoc and JVM diagnostics; Maven 3.9.16; Gradle 9.8.1; Node.js 24, npm and npx.

Base image: `JAVA_IMAGE=eclipse-temurin:27-jdk`. These are the configured defaults, not a claim that the versions are the latest releases. `.env` can override supported image/port settings; inspect the actual container with the tools' version commands.

All eight environments also include a full Python standard library, development headers, pip/venv, uv/uvx, Git/Git LFS, GitHub CLI, Azure CLI, AWS CLI v2, Google Cloud CLI (`gcloud`, `gsutil`, `bq`), Terraform, OpenCode, Claude Code and Codex. Common shell/build utilities include SSH client, Bash/completion, curl, wget, jq, ripgrep, zip/unzip, SQLite CLI and tini. Node.js tooling is bundled only in the .NET, Java and Node.js environments.

Shared CLI installation comes from [`../common/install-cli-tools.sh`](../common/install-cli-tools.sh). Use Compose to supply that build context; copying this folder alone or running a bare `docker build .` does not supply it. Requirements: Docker with BuildKit, Compose 2.17+ and internet access; host VS Code plus Dev Containers for desktop editing. See the [repository guide](../../README.md).

## Launch and editor mode

Run from this directory using Bash (WSL or a Bash-compatible shell on Windows):

```sh
./start.sh --browser  # Enable code-server
./start.sh --desktop  # Keep the container running for host VS Code
./start.sh            # Reuse the saved choice; browser is the fresh default
```

The switches save `EDITOR_MODE=browser` or `EDITOR_MODE=desktop` in `.env`. The script creates `src/` and `.env` if absent, invokes Compose with `--build --wait`, and uses the build cache when possible. Existing exported shell variables take precedence over `.env` in Compose. On Linux, automatic UID/GID matching happens only when the script creates `.env`; if you copy `.env.example`, set `DEV_UID`/`DEV_GID` yourself before building. The container runs as `developer`.

| Behavior | Browser mode | Desktop mode |
| --- | --- | --- |
| Main process, under tini | code-server | `sleep infinity` |
| Browser editor | http://localhost:8082 | Not running |
| Health check | HTTP `/healthz` on container port 8080 | Desktop startup marker |
| Host VS Code attachment | Available | Available |
| SDKs, CLI tools, source and volumes | Same environment | Same environment |

Changing the mode changes the container environment, so Compose recreates the container. Running terminals, application servers and other processes stop; files outside bind mounts/named volumes are lost. Mounted source and named volumes survive. Rebuilds are still invoked by `start.sh`, but mode selection itself does not change the image. This is one switchable Compose project, not two simultaneous stacks. The browser-port mapping remains reserved in desktop mode even though no HTTP editor listens there; application/frontend mappings remain available. The code-server package stays installed in both modes.

## Desktop Microsoft VS Code

1. Run `./start.sh --desktop` (or keep browser mode if you also want code-server).
2. Install Microsoft VS Code and the Dev Containers extension on the host.
3. Open this `dev/java` folder containing `.devcontainer`, not only `src`.
4. Choose **Dev Containers: Reopen in Container**. The configuration uses the saved Compose mode and opens `/workspace/src` as `developer`.

Closing VS Code leaves the container running. Its UI runs on the host; terminals, builds and remote language tools run inside the container. Desktop extensions come from Microsoft's Marketplace; code-server uses Open VSX. Browser extension seeding runs only in browser mode and only once per `editor-data` volume. Desktop attachment is not verified by `start.sh`.

- Bundled browser extension IDs: `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`, `vscjava.vscode-gradle`, `vscjava.vscode-java-dependency`, `EditorConfig.EditorConfig`, `humao.rest-client`.
- Requested desktop extension IDs: `redhat.java`, `vscjava.vscode-java-debug`, `vscjava.vscode-java-test`, `vscjava.vscode-maven`, `vscjava.vscode-gradle`, `vscjava.vscode-java-dependency`, `EditorConfig.EditorConfig`, `humao.rest-client`.

## Ports and applications

All host bindings use `127.0.0.1`. Defaults can be overridden in `.env`:

| Setting | Host port | Container port |
| --- | --- | --- |
| `CODE_SERVER_PORT` | 8082 | 8080 |
| `WEB_PORT` | 8081 | 8081 |
| `FRONTEND_PORT` | 5174 | 5173 |
| `DEBUG_PORT` | 5005 | 5005 |

Application servers must bind to `0.0.0.0:8081` inside the container; access them at http://localhost:8081. Starting an environment starts its editor/keep-alive, not your application.

Run project commands from the container terminal under `/workspace/src`:

```sh
java --version
javac --version
# From your existing project, prefer its wrapper:
./mvnw verify
./mvnw spring-boot:run
# Or use its Gradle wrapper:
./gradlew build
./gradlew bootRun
```

Compose supplies `SERVER_ADDRESS=0.0.0.0` and `SERVER_PORT=8081` for Spring Boot; other frameworks need equivalent settings. For JVM remote debugging, pass `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`. The host debug port defaults to 5005. Project framework dependencies and Maven/Gradle wrappers remain project-managed; use versions compatible with the selected JDK.

For an existing Vite project, use `npm run dev -- --host 0.0.0.0 --port 5173` and visit http://localhost:5174.

## Source, configuration and persistence

Keep your application repository in this folder's `src/`; it is mounted at `/workspace/src`. Git commits made inside that application repository belong to it. Other arbitrary host folders are not automatically mounted. Once attached to the container, VS Code's **Add Folder to Workspace** browses container paths; mount additional host folders explicitly if needed.

| Mount | Container path |
| --- | --- |
| `./src` | `/workspace/src` |
| `editor-data` | `/home/developer/.local/share/code-server` |
| `developer-config` | `/home/developer/.config` |
| `opencode-data` | `/home/developer/.local/share/opencode` |
| `pip-cache` | `/home/developer/.cache/pip` |
| `uv-cache` | `/home/developer/.cache/uv` |
| `maven-cache` | `/home/developer/.m2` |
| `gradle-cache` | `/home/developer/.gradle` |
| `npm-cache` | `/home/developer/.npm` |

`editor-data` retains code-server settings/extensions; `developer-config` retains Git configuration, CLI settings that use `.config`, and AI configuration. `opencode-data` retains OpenCode data. The listed language/pip/uv volumes retain caches, not every package or setting installed manually. Desktop VS Code's remote server/extensions directory is not a named volume; declared extensions can be reinstalled on a new container. Host VS Code UI settings are separate.

Run `claude`, `codex`, or `opencode` from your project directory and configure your own account/provider. AI settings use `.config/claude`, `.config/codex`, `.config/opencode` and OpenCode's mounted data directory. These Compose files do not mount host credential folders; host IDE authentication integrations are separate. GitHub CLI and Google Cloud CLI default to `.config` locations; AWS `~/.aws` and Azure `~/.azure` defaults are **not mounted**. See [CLI credentials](../../README.md#cli-credentials-and-persistence) for persistent-path options.

No database is included. To reach a separately launched repository service, run from this environment folder on the host:

```sh
docker network connect dev-services "$(docker compose ps -q dev)"
```

The service's `start.sh` must have created that external network first. Use the service hostname and container port. Repeat the attachment after container recreation, including mode changes, or add the external network to this environment's Compose configuration.

## Configure, update and stop

Use the settings listed in `.env.example`. Do not overwrite an existing `.env` when changing only the mode or one setting. To initialize custom settings on a fresh checkout, copy `.env.example` to `.env` and edit it before launching.

```sh
docker compose ps
docker compose exec dev bash
docker compose logs -f dev
docker compose stop
# Resume using the saved mode:
./start.sh
# Remove the container/network, retaining mounted source and named volumes:
docker compose down
# Refresh base-image patches and upstream-installed tools:
docker compose build --pull --no-cache
./start.sh
```

The shared installer resolves upstream Git, gh, Terraform and cloud CLI releases when its build layer executes; native AI installers resolve their current releases too. `--pull` refreshes referenced images, while `--no-cache` reruns installers. A normal launch may reuse cached versions. Full refreshes retain the configured language major and explicitly pinned tool versions. Project lockfiles and image/tag overrides control project reproducibility; these development images are not fully version-pinned.

Java also exposes `MAVEN_VERSION` and `GRADLE_VERSION` build arguments through `.env`; both are explicitly pinned in the defaults.

`docker compose down --volumes` permanently deletes this environment's named settings, credentials, caches and OpenCode data. The host `src/` bind mount remains. Files in unmounted container paths disappear on replacement even without `--volumes`.

## Local-only use

Use on your local machine only. Keep localhost port bindings and do not expose editors, apps or debuggers to an untrusted network. Desktop mode stops code-server but does not add a security boundary around other running applications or Docker access.
