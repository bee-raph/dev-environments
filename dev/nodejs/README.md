# Node.js development environment

## Tools

Node.js 26, npm/npx, pnpm, Yarn Classic, TypeScript, ts-node, ESLint and Prettier.

Includes Git/Git LFS, SSH client, Bash/completion, build-essential, curl, wget,
jq, ripgrep, zip/unzip, SQLite CLI, and code-server with stack extensions,
EditorConfig and REST Client. No database server is started.

## Launch

Start Docker and run from this folder:

```sh
./start.sh
```

Open http://localhost:8086. All published ports bind
to localhost. Optional ports and base image settings are in `.env.example`;
copy it to `.env` before launching to customize them. The script sets the host
UID/GID on Linux when generating `.env`. The container runs as non-root.

Source on the host in `nodejs/src` is mounted at `/workspace/src`. Editor settings,
extensions, Git config and language caches persist in named volumes.

## Desktop Microsoft VS Code

Install VS Code and the Dev Containers extension on the host, open this folder,
and select **Dev Containers: Reopen in Container**. The included configuration
opens the same source in the Compose container and installs extensions from
Microsoft's Marketplace. code-server uses Open VSX and remains available.
Desktop attachment is not verified automatically by the launch script.

## Application ports

Run application servers on **0.0.0.0:8000** inside the container; access them at
http://localhost:3000. For Vite use
`npm run dev -- --host 0.0.0.0 --port 5173` and open http://localhost:5178
(the Node.js environment includes npm; install frontend tooling separately
in the other environments if needed). Editor port 8080 is reserved.

## Manage

```sh
docker compose exec dev bash
docker compose logs -f dev
docker compose stop
docker compose down
# Refresh installed tools and base-image patches:
docker compose build --pull --no-cache
./start.sh
```

`down` keeps volumes; `down --volumes` deletes editor settings/caches. Source files
in `src/` remain on the host. Git credentials are configured in the container,
not copied from the host. Git global configuration persists in the config volume.
Change `BASE_IMAGE` to select a compatible runtime version, then rebuild.

## Node.js projects

Use `npm init`, `npm install`, `npm test`, and `npm run dev`. npm, pnpm and Yarn
Classic are available. Prefer project-local TypeScript/ESLint/Prettier versions
when projects specify them. Built-in JS/TS support and the Node debugger are
included in the editor. Runtime defaults to current stable Node 26; change
BASE_IMAGE for projects requiring another major. Native addons can compile
using the included Python and C/C++ build tools.

Toolchain reference: https://nodejs.org/en/download

## Security

Use this environment on your local machine only. Keep published ports bound
to localhost; do not expose the editor or development ports to the internet
or an untrusted network.

## AI coding CLIs

Claude Code (`claude`) and OpenAI Codex (`codex`) are installed as the non-root developer user. Run either command from your project directory in the editor terminal. Sign in separately for each environment; for Codex in a container use `codex login --device-auth`, then follow the link and code on your host browser. Run `claude` and follow its sign-in instructions.

Their settings, sessions and Linux file-based credentials live under `/home/developer/.config/claude` and `/home/developer/.config/codex` in the existing `developer-config` volume. Container replacement preserves them; `docker compose down --volumes` deletes them. Credentials are not built into images or committed to this repository.

To add the tools to an existing environment or refresh the installed versions, run `docker compose build --pull --no-cache` followed by `./start.sh`. Claude Code and Codex install their latest release. These are terminal tools available through both editors; no AI editor extensions are installed.

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

Git, GitHub CLI (`gh`), Azure CLI (`az`), AWS CLI v2 (`aws`), Google Cloud CLI (`gcloud`, `gsutil`, `bq`), and Terraform CLI (`terraform`) are included. Run `docker compose build --pull --no-cache` and then `./start.sh` to refresh tools from upstream.

Terraform installs the current stable release from HashiCorp for the container's CPU architecture, with its archive checked against the published SHA-256 sums. Run `terraform init`, `terraform validate`, and `terraform plan` from your project directory under `/workspace/src`. Use your cloud provider's normal credentials; none are embedded in the image. Refresh Terraform with the full rebuild command above.

## Editor mode and OpenCode

Use one configuration for both editor flavors:

```sh
./start.sh --browser  # Run code-server (default)
./start.sh --desktop  # Keep the dev container running for desktop VS Code
```

These switches save `EDITOR_MODE=browser` or `EDITOR_MODE=desktop` in `.env`. You can also edit that setting directly, then run `./start.sh`. Mode changes recreate the container without rebuilding an unchanged image. Source files and named volumes are shared between modes.

In desktop mode code-server is not started. Open this environment folder in host VS Code and choose **Dev Containers: Reopen in Container**. Its existing configuration honors the saved `.env` choice. The browser port mapping remains reserved, but there is no HTTP editor listening; application/frontend ports keep working. Both modes retain the same SDKs, AI CLIs, Git and cloud tools.

Terraform is included via the shared installer. OpenCode is installed using its official native installer; run `opencode` from your project terminal and configure your model/provider account there. OpenCode configuration persists in the existing `developer-config` volume and its data in `opencode-data`. Rebuild with `docker compose build --pull --no-cache`, then start your chosen mode to install/refresh the CLI. No provider credentials are embedded in images.
