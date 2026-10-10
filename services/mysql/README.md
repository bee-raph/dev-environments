# mysql local development service

## Launch and credentials

Start Docker, then run from this folder:

```sh
./start.sh
```

The script generates a strong password in a local `.env` (mode 600) on first
launch. Use account **developer** and `DEVELOPER_PASSWORD` from that file.
`.env` is excluded from Git. Copy `.env.example` to `.env` and replace the
placeholders if you prefer to configure credentials and ports yourself.

Permissions: Global ALL PRIVILEGES with GRANT OPTION, including administration of all databases.

Connect from your host at `localhost:3306`. The service publishes only on
localhost and retains its data in a named Docker volume.

Default application database: **app**.

A separate `root` bootstrap password is stored as `ROOT_PASSWORD` in `.env`.

## Connect from a development container

All service launch scripts create/use the shared Docker network `dev-services`.
Connect a running development container once:

```sh
# Run from your language environment folder, e.g. ../../dev/dotnet:
docker network connect dev-services "$(docker compose ps -q dev)"
```

Your application can then connect to hostname **mysql**, port **3306**, and
authenticate as `developer` with the password in this service's `.env`.
Use service names inside containers: `localhost` there refers to the development
container itself. The manual network attachment must be repeated after recreating
the development container. For a persistent connection, add this external
network to its Compose configuration and attach its `dev` service to it.

## Manage and data lifecycle

```sh
docker compose logs -f mysql
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
