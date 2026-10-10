# Python development environment

## Tools

Python 3.14, pip, venv, uv, pytest, Ruff, mypy, debugpy, IPython and build.

Includes Git/Git LFS, SSH client, Bash/completion, build-essential, curl, wget,
jq, ripgrep, zip/unzip, SQLite CLI, and code-server with stack extensions,
EditorConfig and REST Client. No database server is started.

## Launch

Start Docker and run from this folder:

```sh
./start.sh
```

Open http://localhost:8083. All published ports bind
to localhost. Optional ports and base image settings are in `.env.example`;
copy it to `.env` before launching to customize them. The script sets the host
UID/GID on Linux when generating `.env`. The container runs as non-root.

Source on the host in `python/src` is mounted at `/workspace/src`. Editor settings,
extensions, Git config and language caches persist in named volumes.

## Desktop Microsoft VS Code

Install VS Code and the Dev Containers extension on the host, open this folder,
and select **Dev Containers: Reopen in Container**. The included configuration
opens the same source in the Compose container and installs extensions from
Microsoft's Marketplace. code-server uses Open VSX and remains available.
Desktop attachment is not verified automatically by the launch script.

## Application ports

Run application servers on **0.0.0.0:8000** inside the container; access them at
http://localhost:8000. For Vite use
`npm run dev -- --host 0.0.0.0 --port 5173` and open http://localhost:5175
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

## Python projects

Use per-project environments: `uv init`, `uv add <package>`, and `uv run pytest`.
Or use `python -m venv .venv` then `source .venv/bin/activate`. Tool commands
pytest/Ruff/mypy are preinstalled in `/opt/devtools`; dependencies for your
application belong in its own environment. Flask/FastAPI/Django are project
dependencies, not globally installed. Python 3.14 is the newest available stable official image at creation time;
Python 3.15 has been released but its Docker tag is not yet published. Update
`BASE_IMAGE` when the desired stable image becomes available.

Toolchain reference: https://blog.python.org/2026/10/python-3150-final-is-here/

## Security

Use this environment on your local machine only. Keep published ports bound
to localhost; do not expose the editor or development ports to the internet
or an untrusted network.
