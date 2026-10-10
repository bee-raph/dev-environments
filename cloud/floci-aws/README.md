# Floci for AWS

Run `./start.sh`. Endpoint: `http://localhost:4566`. Local SDK settings are in the generated `.env`, which is excluded from Git. Floci emulates cloud APIs; it does not provision a database-style administrator account. The `developer` identity/settings are for local SDK use, and the generated `DEVELOPER_PASSWORD` is not a cloud access-control boundary.

Set `AWS_ACCESS_KEY_ID=developer`, `AWS_SECRET_ACCESS_KEY` from `.env`, and `AWS_DEFAULT_REGION=us-east-1`. Always supply `--endpoint-url http://localhost:4566` to AWS CLI commands. For example: `aws --endpoint-url http://localhost:4566 s3 mb s3://developer-example`. Use path-style S3 addressing in SDKs.

For applications on `dev-services`, replace `localhost` with `floci-aws` and use port `4566`. APIs returning resource URLs default to localhost; override `FLOCI_BASE_URL` in Compose for clients inside containers.

Persistent state lives in a named volume. `docker compose stop` stops it; `./start.sh` resumes it. `docker compose down` retains state; `docker compose down --volumes` permanently deletes it. Image and host port can be overridden through `.env`.

Run `./start.sh --docker` to enable Docker-backed runtimes. This mounts the host Docker socket and gives Floci control of the host engine. With this mode, use `docker compose -f compose.yaml -f compose.docker.yaml` for subsequent lifecycle commands. Runtime-created containers/volumes may require separate cleanup. Runtime sidecars can publish additional host ports; configure their bind addresses before using them, since the main Compose localhost binding does not constrain sidecar ports. Additional protocol ports and service-specific SDK configuration may be needed for individual cloud services. Emulator coverage and behavior differ from the real cloud.

Use on your local machine only. Keep the localhost binding; enable Docker access only for trusted local workloads.

Official implementation and supported APIs: https://github.com/floci-io/floci
