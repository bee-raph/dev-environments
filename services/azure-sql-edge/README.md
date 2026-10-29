# Azure SQL Edge

A local SQL Edge service based on `mcr.microsoft.com/azure-sql-edge:latest`, with persistent data and a `developer` login granted `sysadmin` rights. Microsoft Container Registry currently advertises both `linux/arm64/v8` and `linux/amd64` variants for this tag. Docker selects the native host architecture; neither the server nor the initialization container forces x64 emulation.

Microsoft retired ARM64 support in September 2023 and retired SQL Edge as a product in September 2025. The ARM64 image remains published, but this service uses a legacy, unsupported database engine. Treat it as a local compatibility/testing environment, not as an equivalent to a current SQL Server release.

## Launch

Start Docker, then run from this folder:

```sh
./start.sh
```

The script generates `.env` with separate `DEVELOPER_PASSWORD` and `SA_PASSWORD` values, creates the shared `dev-services` network, builds the image, waits for SQL readiness, creates database `app`, and creates or updates the `developer` administrator login. `.env` is excluded from Git and the build context.

The Dockerfile adds Microsoft's Go-based `sqlcmd` to the official SQL Edge image because its ARM64 variant lacks the ODBC client. The SQL client is downloaded for the target architecture, and the initialization container uses the same native image. SQL Edge still runs as the base image's non-root database user.

## Connect

| Setting | Host application | Development container on `dev-services` |
| --- | --- | --- |
| Server | `localhost,1434` | `azure-sql-edge,1433` |
| Database | `app` | `app` |
| Username | `developer` | `developer` |
| Password | `DEVELOPER_PASSWORD` in `.env` | Same |

For example, a .NET connection string for a containerized application is:

```text
Server=azure-sql-edge,1433;Database=app;User Id=developer;Password=<DEVELOPER_PASSWORD>;Encrypt=True;TrustServerCertificate=True;
```

For a host application, replace the server with `localhost,1434`. The distinct host port lets this service coexist with the SQL Server service on port 1433. Do not substitute its named data volume for SQL Server's volume; the engines and on-disk versions differ.

From your language environment folder, connect its running container to the shared network:

```sh
docker network connect dev-services "$(docker compose ps -q dev)"
```

Run an authenticated query without putting the password in the command arguments:

```sh
docker compose run --rm --no-deps --entrypoint /bin/bash init -c \
  'SQLCMDPASSWORD="$DEVELOPER_PASSWORD" sqlcmd -S azure-sql-edge -U developer -d app -C -b -Q "SELECT @@VERSION; SELECT IS_SRVROLEMEMBER('\''sysadmin'\'');"'
```

You can also connect through desktop VS Code's SQL Server extension, SSMS, or a compatible SQL client.

## Lifecycle and credentials

```sh
./smoke-test.sh
docker compose ps
docker compose logs -f azure-sql-edge
docker compose stop
./start.sh
# Remove containers while retaining database files:
docker compose down
```

The named `data` volume retains database files after container replacement. `docker compose down --volumes` permanently deletes them. `./start.sh` synchronizes the developer password on each launch. The `sa` password is initialized with fresh database files: to rotate it on an existing volume, change it through SQL first, then update `.env`.

Optional settings are listed in `.env.example`. `SERVICE_IMAGE` selects the base image, `SQLCMD_VERSION` selects the native client, `SERVICE_PORT` controls the host port, and `MEMORY_LIMIT_MB` controls the database memory limit. Use `docker compose build --pull` followed by `./start.sh` to refresh the base image; an unchanged retired tag may have no newer build. Preserve backups before changing image versions or upgrading database files.

## Security and limitations

Use on your local machine only. Published ports bind to `127.0.0.1`; keep that binding and avoid untrusted workloads on `dev-services`. The example trusts the local server's self-signed TLS certificate. Go-based `sqlcmd` is configured with `GODEBUG=x509negativeserial=1` in these two containers to accept the legacy engine's certificate serial-number format. The shared developer administrator is for local development. SQL Edge's SQL feature set, engine version and lifecycle differ from supported SQL Server, so test production-targeted features against the actual target engine.

References: [Microsoft's ARM64 retirement announcement](https://techcommunity.microsoft.com/t5/sql-server-blog/azure-sql-edge-update-september-2023/bc-p/4158175/highlight/true), [SQL Edge retirement](https://learn.microsoft.com/lifecycle/announcements/azure-products-retirement-september-2025), and [Microsoft sqlcmd installation](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install).
