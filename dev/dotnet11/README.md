# .NET 11 RC3 web development environment

## Tools

- Pinned .NET 11 RC3 SDK from Microsoft's `sdk:11.0.100-rc.3` image, including
  ASP.NET Core, NuGet, MSBuild, test, format, user-secrets and watch commands.
- code-server: browser-based VS Code, with persistent settings and extensions.
- Free/Libre C# extension (`muhammad-sammy.csharp`), REST Client, EditorConfig.
- Entity Framework Core CLI 11 RC3 and dotnet-outdated for dependency inspection.
- Node.js 24 LTS, npm and npx for JavaScript/TypeScript frontend development.
- Git, Git LFS, OpenSSH client, Bash and completion.
- curl, wget, jq, ripgrep, zip/unzip, build-essential, procps, less, nano,
  SQLite CLI and tini for process/signal handling.

No database server is started. Future database services can join this Compose
project's default network; use their service names as connection hosts.

## Launch

Install/start Docker with Compose, then from this directory:

```sh
./start.sh
```

This creates `.env` for optional settings, builds the image and waits for the
editor to become healthy. Open http://localhost:8088. Published ports bind only to localhost. To configure ports,
copy `.env.example` to `.env` before launching and edit it.

`src/` on your host is mounted at `/workspace/src`. Place or clone projects
there. Settings/extensions, Git configuration, NuGet packages and npm cache
use named volumes and survive container recreation. The container runs as a
non-root user. On Linux, the launch script uses your UID/GID for source ownership.

## Create and run a web app

In the editor's terminal:

```sh
dotnet new webapp -n MyWebApp
cd MyWebApp
dotnet watch --non-interactive run --no-launch-profile --urls http://0.0.0.0:5000
```

Open http://localhost:5001. Polling file watching is enabled for Docker mounts.
For a Vite frontend, run `npm run dev -- --host 0.0.0.0 --port 5173` and open
http://localhost:5180. All published ports bind only to the host's localhost.
The default application URL uses HTTP, avoiding container certificate trust setup.

Configure Git once in the terminal:

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Git config persists in the configuration volume. Host Git/SSH credentials are
not copied; configure credentials inside the container when needed.

## Manage

```sh
docker compose logs -f dev
docker compose exec dev bash
docker compose stop
docker compose down
# Rebuild the configured SDK, Node.js and editor/tool installations:
docker compose build --pull --no-cache
./start.sh
```

`down` preserves named volumes and source code. `down --volumes` deletes editor
settings and caches; source files in `src/` remain on the host.

The SDK and EF CLI are pinned to RC3. This environment has its own Compose project,
source folder, caches and configuration volumes. It can run beside `dev/dotnet`.
Host ports are 8088 (editor), 5001 (application), and 5180 (frontend); container
ports remain 8080, 5000, and 5173. Keep application servers bound to
`0.0.0.0:5000` inside the container.

## Upgrade to .NET 11 final

Once the final SDK image and EF packages are published, set these values in `.env`:

```dotenv
DOTNET_IMAGE=mcr.microsoft.com/dotnet/sdk:11.0
EF_VERSION=11.*
```

Then run:

```sh
docker compose build --pull
./start.sh
docker compose exec dev dotnet --info
docker compose exec dev dotnet ef --version
```

No Dockerfile changes or volume deletion are needed. Upgrade your project's
prerelease package references too. If the project has a `global.json` pinned to
RC3, update its SDK version/roll-forward policy for the final SDK; changing the
container image does not edit project files. To create a fixed SDK selection,
run `dotnet new globaljson --sdk-version "$(dotnet --version)"` in the project.
Stable `dotnet-outdated` is installed with tool runtime roll-forward enabled so
it can run on the .NET 11 runtime.

code-server uses Open VSX, not Microsoft's Marketplace. The bundled C# extension
is the Free/Libre fork, not C# Dev Kit. SDK build/test/watch commands work
independently of editor extensions; editor debugging and language features depend
on the fork's support for your SDK and architecture.

References: https://dotnet.microsoft.com/download and
https://coder.com/docs/code-server/FAQ and
https://github.com/muhammadsammy/free-vscode-csharp.

## Microsoft VS Code (desktop)

The same container supports official Microsoft VS Code and its Marketplace,
including Microsoft's C# extension and C# Dev Kit:

1. Run `./start.sh` once to create `.env` and launch the container.
2. Install Microsoft VS Code and its **Dev Containers** extension on the host.
3. Open this `dotnet11/` directory in desktop VS Code.
4. Run **Dev Containers: Reopen in Container** from the Command Palette.

The included `.devcontainer/devcontainer.json` connects to the Compose `dev`
service and opens `/workspace/src`. SDKs, terminals, builds and remote extensions
run inside the container; the desktop editor UI runs on the host. code-server
remains available at http://localhost:8088. The two editors maintain separate
extension installations. Closing desktop VS Code leaves the container running.

C# Dev Kit use is subject to Microsoft's license terms:
https://code.visualstudio.com/docs/csharp/cs-dev-kit-faq.

## Security

Use this environment on your local machine only. Keep published ports bound
to localhost; do not expose the editor or development ports to the internet
or an untrusted network.

## AI coding CLIs

Claude Code (`claude`) and OpenAI Codex (`codex`) are installed as the non-root developer user. Run either command from your project directory in the editor terminal. Sign in separately for each environment; for Codex in a container use `codex login --device-auth`, then follow the link and code on your host browser. Run `claude` and follow its sign-in instructions.

Their settings, sessions and Linux file-based credentials live under `/home/developer/.config/claude` and `/home/developer/.config/codex` in the existing `developer-config` volume. Container replacement preserves them; `docker compose down --volumes` deletes them. Credentials are not built into images or committed to this repository.

To add the tools to an existing environment or refresh the installed versions, run `docker compose build --no-cache` followed by `./start.sh`. Claude Code installs its stable channel; Codex installs the current release. These are terminal tools available through both editors; no AI editor extensions are installed.

## Python available in this environment

Includes a complete Python 3 standard library, development headers, pip, venv, and the standalone `uv`/`uvx` tools. `python` and `python3` are available. The Python environment uses the full official Python 3.14 image; the other environments use their base distribution's Python version.

Create project environments inside your mounted source folder, as `developer`:

```sh
python -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
# Install your project's dependencies with pip, or use uv:
uv pip install -r requirements.txt
# For a project with pyproject.toml and uv.lock:
uv sync
```

Use a project virtual environment for package installation; system Python and bundled tool environments are image-managed. pip and uv caches persist in named volumes. Rebuild with `docker compose build --pull`, then run `./start.sh` to apply these additions to an existing container.
