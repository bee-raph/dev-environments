# Go development environment

## Tools

Go 1.27, gofmt, go test/vet, gopls, Delve and Staticcheck.

Includes Git/Git LFS, SSH client, Bash/completion, build-essential, curl, wget,
jq, ripgrep, zip/unzip, SQLite CLI, and code-server with stack extensions,
EditorConfig and REST Client. No database server is started.

## Launch

Start Docker and run from this folder:

```sh
./start.sh
```

Open http://localhost:8085. All published ports bind
to localhost. Optional ports and base image settings are in `.env.example`;
copy it to `.env` before launching to customize them. The script sets the host
UID/GID on Linux when generating `.env`. The container runs as non-root.

Source on the host in `go/src` is mounted at `/workspace/src`. Editor settings,
extensions, Git config and language caches persist in named volumes.

## Desktop Microsoft VS Code

Install VS Code and the Dev Containers extension on the host, open this folder,
and select **Dev Containers: Reopen in Container**. The included configuration
opens the same source in the Compose container and installs extensions from
Microsoft's Marketplace. code-server uses Open VSX and remains available.
Desktop attachment is not verified automatically by the launch script.

## Application ports

Run application servers on **0.0.0.0:8000** inside the container; access them at
http://localhost:8002. For Vite use
`npm run dev -- --host 0.0.0.0 --port 5173` and open http://localhost:5177
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

## Go projects

Use `go mod init example.com/myapp`, `go test ./...`, `go vet ./...`,
`staticcheck ./...`, and `go run .`. gopls and Delve are preinstalled.
Module/build caches persist; tools installed with `go install` in your home
are recreated after container replacement, so add permanent tools to the
Dockerfile. SYS_PTRACE is enabled for debugging.

Toolchain reference: https://go.dev/dl/

## Security

Use this environment on your local machine only. Keep published ports bound
to localhost; do not expose the editor or development ports to the internet
or an untrusted network.

## AI coding CLIs

Claude Code (`claude`) and OpenAI Codex (`codex`) are installed as the non-root developer user. Run either command from your project directory in the editor terminal. Sign in separately for each environment; for Codex in a container use `codex login --device-auth`, then follow the link and code on your host browser. Run `claude` and follow its sign-in instructions.

Their settings, sessions and Linux file-based credentials live under `/home/developer/.config/claude` and `/home/developer/.config/codex` in the existing `developer-config` volume. Container replacement preserves them; `docker compose down --volumes` deletes them. Credentials are not built into images or committed to this repository.

To add the tools to an existing environment or refresh the installed versions, run `docker compose build --no-cache` followed by `./start.sh`. Claude Code installs its stable channel; Codex installs the current release. These are terminal tools available through both editors; no AI editor extensions are installed.
