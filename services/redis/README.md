# redis local development service

## Launch and credentials

Start Docker, then run from this folder:

```sh
./start.sh
```

The script generates a strong password in a local `.env` (mode 600) on first
launch. Use account **developer** and `DEVELOPER_PASSWORD` from that file.
`.env` is excluded from Git. Copy `.env.example` to `.env` and replace the
placeholders if you prefer to configure credentials and ports yourself.

Permissions: ACL user with every command, every key and every Pub/Sub channel allowed.

Connect from your host at `localhost:6379`. The service publishes only on
localhost and retains its data in a named Docker volume.

Use Redis ACL authentication with username `developer`, rather than only a
password. AOF persistence is enabled. The startup script derives an ACL password
hash from `.env` each time; changing the password and recreating the container
applies it. The default Redis account is disabled.

```sh
docker compose exec redis sh -c 'REDISCLI_AUTH="$DEVELOPER_PASSWORD" redis-cli --user developer ping'
```

## Connect from a development container

All service launch scripts create/use the shared Docker network `dev-services`.
Connect a running development container once:

```sh
# Run from your language environment folder, e.g. ../../dev/dotnet:
docker network connect dev-services "$(docker compose ps -q dev)"
```

Your application can then connect to hostname **redis**, port **6379**, and
authenticate as `developer` with the password in this service's `.env`.
Use service names inside containers: `localhost` there refers to the development
container itself. The manual network attachment must be repeated after recreating
the development container. For a persistent connection, add this external
network to its Compose configuration and attach its `dev` service to it.

## Manage and data lifecycle

```sh
docker compose logs -f redis
docker compose stop
./start.sh
docker compose down
```

`down` retains data. **`docker compose down --volumes` deletes this service's
stored data.** Initialization settings for MySQL and PostgreSQL apply
only to an empty data volume. Changing `.env` does not change an existing
account's password in those services: update it using the service's admin tools,
or deliberately reset disposable data. Redis reads credentials on each startup;
SQL Server and RabbitMQ launch scripts update the developer password.

## Security

Use this service on your local machine only. Keep ports bound to localhost and
do not expose it to the internet or an untrusted network. The developer account
has full service administration rights for development convenience. Keep real
secrets out of Git, and use separate service accounts for production deployments.
These service containers provide database/broker processes; use a language
environment for Git and VS Code.
