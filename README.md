# Docker development environments

Ready-to-use development workspaces for .NET, Java, Python, Rust, Go, Node.js,
and C/C++. Each stack lives in its own folder and runs in a separate Docker
container, keeping its SDKs, compilers, editors, and dependencies off your host.

Every language environment includes Git, Git LFS, a browser-based VS Code editor
(code-server), and configuration for connecting desktop Microsoft VS Code.
You can run environments independently or alongside one another.

## Requirements

- Docker Desktop on macOS/Windows, or Docker Engine on Linux.
- Docker Compose with support for `docker compose up --wait`.
- A browser for code-server.
- Optional: Microsoft VS Code with the **Dev Containers** extension for the
  desktop editing experience.
- An internet connection for the initial image build and tool/extension downloads.

## Quick start

```sh
git clone https://github.com/bee-raph/dev-environments.git
cd dev-environments/python
./start.sh
```

Choose any environment folder instead of `python`. On Windows, use WSL or a
Bash-compatible shell for the launch script. Alternatively, configure `.env`
from `.env.example`, then run `docker compose up -d --build --wait`.

The launch script creates the source folder and an optional `.env` configuration,
builds the image, starts the container, and waits for the editor health check.
The initial build can take several minutes; subsequent launches reuse the image
layers and persistent caches.

## Available environments

| Folder | Main tools | Browser editor | Application host port | Frontend host port |
| --- | --- | --- | --- | --- |
| [dotnet](dotnet/README.md) | .NET 10 SDK, ASP.NET Core, EF CLI, Node.js | [8080](http://localhost:8080) | 5000 | 5173 |
| [java](java/README.md) | JDK 27, Maven, Gradle, Node.js | [8082](http://localhost:8082) | 8081 | 5174 |
| [python](python/README.md) | Python 3.14, uv, pytest, Ruff, mypy | [8083](http://localhost:8083) | 8000 | 5175 |
| [rust](rust/README.md) | Stable Rust, Cargo, rustfmt, Clippy | [8084](http://localhost:8084) | 8001 | 5176 |
| [go](go/README.md) | Go 1.27, gopls, Delve, Staticcheck | [8085](http://localhost:8085) | 8002 | 5177 |
| [nodejs](nodejs/README.md) | Node.js 26, npm, pnpm, Yarn, TypeScript | [8086](http://localhost:8086) | 3000 | 5178 |
| [cpp](cpp/README.md) | GCC, Clang, CMake, Ninja, GDB/LLDB, Conan | [8087](http://localhost:8087) | 8003 | 5179 |

See each environment's README for the complete tool list and stack-specific commands.
Java also publishes debugger port 5005. Frontend port mappings are provided in
all environments; Node.js tooling is bundled in .NET, Java, and Node.js.

## How the folders work

Each environment contains:

```text
Dockerfile                    SDKs, tools, editor and bundled extensions
compose.yaml                  Container, ports, source mount and persistent volumes
start.sh                      Build and launch helper
entrypoint.sh                 Editor startup and initial extension setup
.env.example                  Optional port, image and user-ID configuration
.devcontainer/devcontainer.json  Desktop VS Code connection settings
src/                          Your source code, stored on the host
README.md                     Environment-specific instructions
```

The host `src/` directory is bind-mounted at `/workspace/src` in the container.
Edits from either editor or the host appear in the same files immediately.
Clone application repositories into `src/`, or place your existing projects
there. Each application can retain its own Git repository independently of
this environment configuration repository. Do not commit application code into
this repository unless that is intentional.

Docker named volumes retain editor settings/extensions, Git configuration, and
language package/build caches when containers are replaced. Each environment
has its own Compose project name, network, and volumes. Containers run as a
non-root `developer` user. On Linux, the launch script uses the host UID/GID
when creating `.env`, allowing writes to the source mount.

## Connect desktop Microsoft VS Code

1. Start the desired environment using its `./start.sh`.
2. Install Microsoft VS Code on the host and install **Dev Containers**
   (`ms-vscode-remote.remote-containers`).
3. Open the environment folder, such as `dev-environments/python`, in VS Code.
   Open the folder containing `.devcontainer`, rather than only `src`.
4. Open the Command Palette and select **Dev Containers: Reopen in Container**.
5. VS Code connects to the Compose `dev` service and opens `/workspace/src`.
   The environment's configured language extensions install automatically.

The desktop editor UI runs on your host. Its terminal, language servers,
debuggers, builds, and remote extensions run inside the container. Confirm the
remote connection in VS Code's lower-left corner; terminal commands such as
`python --version`, `go version`, or `dotnet --version` use container tools.
Closing VS Code leaves the container running. Stop it with Compose when finished.

Desktop VS Code uses Microsoft's Marketplace. The browser editor uses Open VSX
and maintains its own extension installation. Settings and available extensions
may differ between the editors; both edit the same mounted source files.

## Connect through a browser

After startup, open the environment's browser editor URL from the table above.
The editor opens `/workspace/src`. Use its integrated terminal to clone
repositories, install project dependencies, run tests, and start applications.

## Run and access applications

Application servers must listen on a published **container** port and bind to
`0.0.0.0` inside the container so Docker can forward traffic:

| Environment | Application container port | Default host URL |
| --- | --- | --- |
| .NET | 5000 | http://localhost:5000 |
| Java | 8081 | http://localhost:8081 |
| Python | 8000 | http://localhost:8000 |
| Rust | 8000 | http://localhost:8001 |
| Go | 8000 | http://localhost:8002 |
| Node.js | 8000 | http://localhost:3000 |
| C/C++ | 8000 | http://localhost:8003 |

For example, a Node.js application that reads `PORT` can be launched with
`PORT=8000 npm run dev`. For Vite, use
`npm run dev -- --host 0.0.0.0 --port 5173` and open the host frontend port
listed above. Container port 8080 is reserved for the editor.

Infrastructure services are available in separate folders; see the section below.
They share the `dev-services` network and can be connected to development
containers without combining their lifecycles.

## Configure Git

Run inside the container terminal:

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Global Git configuration persists in the config volume. Configure credentials
inside the environment as needed; host SSH keys and Git credentials are not
automatically mounted.

## Configure and maintain an environment

Run these commands from the chosen environment folder:

```sh
# Customize ports and base image before launch:
cp .env.example .env
# Edit .env, then start:
./start.sh

# View logs or open a terminal:
docker compose logs -f dev
docker compose exec dev bash

# Stop; resume with ./start.sh:
docker compose stop

# Remove the container and network, preserving settings/caches:
docker compose down

# Download newer base-image patches and refresh installed tools:
docker compose build --pull --no-cache
./start.sh
```

`.env` is excluded from Git and the Docker build context. Runtime major versions
are selected in the Dockerfile and Compose defaults; change the image setting
in `.env` to use a different compatible version. Java's Maven and Gradle versions
can also be configured there. Use project dependency files and lockfiles for
application reproducibility.

`docker compose down --volumes` removes persistent editor settings and caches.
Source files in the host `src/` folder remain. Container packages installed
manually are lost on replacement; add permanent tools to the Dockerfile.

## Security

**Use these environments on your local machine only.** Published ports bind to
`127.0.0.1`. Keep that binding and do not expose the editors, application ports,
or debugger ports to the internet or an untrusted network. These configurations
are development workspaces and are not designed for shared or production hosting.
Rust, Go, and C/C++ containers enable `SYS_PTRACE` to support debugging.

## Database and messaging services

Each service folder contains Compose configuration, a launch script, an example
configuration and service-specific documentation. These run independently of
the language environments and retain their data in named volumes.

| Folder | Host endpoint | Developer permissions |
| --- | --- | --- |
| [mysql](mysql/README.md) | localhost:3306 | Global administrator with grant rights |
| [postgresql](postgresql/README.md) | localhost:5432 | Superuser |
| [sqlserver](sqlserver/README.md) | localhost:1433 | sysadmin; x64 Developer edition |
| [redis](redis/README.md) | localhost:6379 | All commands, keys and channels |
| [rabbitmq](rabbitmq/README.md) | localhost:5672; UI localhost:15672 | Administrator and full resource access |

Run `./start.sh` inside a service folder. The script creates `.env` with generated
credentials, creates the shared `dev-services` network, and waits for readiness.
Every service uses username **developer** and stores its password under
`DEVELOPER_PASSWORD` in its own `.env`. MySQL and SQL Server also store separate
bootstrap administrator passwords. Actual `.env` files are excluded from Git.

To connect a running language environment, run this from its folder:

```sh
docker network connect dev-services "$(docker compose ps -q dev)"
```

Connect applications using the service hostname (`mysql`, `postgresql`,
`sqlserver`, `redis`, or `rabbitmq`) and its standard port. Repeat the network
attachment when recreating the development container, or declare `dev-services`
as an external network in that environment's Compose configuration.

For MySQL/PostgreSQL, credentials are initialized only for fresh data volumes.
Editing `.env` does not rotate existing credentials. SQL Server and RabbitMQ
launch scripts synchronize developer credentials; Redis reads them at startup. Service READMEs
explain password changes, persistence, connection details, and SQL Server setup.

## MongoDB and local cloud emulators

| Folder | Local endpoint | Purpose |
| --- | --- | --- |
| [mongodb](mongodb/README.md) | localhost:27017 | MongoDB; developer root administrator |
| [floci-aws](floci-aws/README.md) | localhost:4566 | Local AWS APIs |
| [floci-azure](floci-azure/README.md) | localhost:4577 | Local Azure APIs |
| [floci-gcp](floci-gcp/README.md) | localhost:4588 | Local GCP APIs |

Run `./start.sh` in each folder. These services share `dev-services` with the other database services and persist state in named volumes. Each README explains client configuration. Floci uses local cloud SDK identities rather than database administrator accounts. Its optional `./start.sh --docker` mode enables runtime containers through the host Docker engine; see the security implications in each README. Use these services on your local machine only.
