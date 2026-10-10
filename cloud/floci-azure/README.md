# Floci for AZURE

Run `./start.sh`. Endpoint: `http://localhost:4577`. Local SDK settings are in the generated `.env`, which is excluded from Git. Floci emulates cloud APIs; it does not provision a database-style administrator account. The `developer` identity/settings are for local SDK use, and the generated `DEVELOPER_PASSWORD` is not a cloud access-control boundary.

Use `AZURE_STORAGE_ACCOUNT` and the base64 `AZURE_STORAGE_KEY` from `.env`. Set explicit storage endpoints: `BlobEndpoint=http://localhost:4577/devstoreaccount1;QueueEndpoint=http://localhost:4577/devstoreaccount1-queue;TableEndpoint=http://localhost:4577/devstoreaccount1-table`. Combine these with `DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=<key>` in your connection string. Management APIs also use the local endpoint; point each SDK at the relevant emulator service path.

For applications on `dev-services`, replace `localhost` with `floci-azure` and use port `4577`. APIs returning resource URLs default to localhost; override `FLOCI_AZ_BASE_URL` in Compose for clients inside containers.

Persistent state lives in a named volume. `docker compose stop` stops it; `./start.sh` resumes it. `docker compose down` retains state; `docker compose down --volumes` permanently deletes it. Image and host port can be overridden through `.env`.

Run `./start.sh --docker` to enable Docker-backed runtimes. This mounts the host Docker socket and gives Floci control of the host engine. With this mode, use `docker compose -f compose.yaml -f compose.docker.yaml` for subsequent lifecycle commands. Runtime-created containers/volumes may require separate cleanup. Runtime sidecars can publish additional host ports; configure their bind addresses before using them, since the main Compose localhost binding does not constrain sidecar ports. Additional protocol ports and service-specific SDK configuration may be needed for individual cloud services. Emulator coverage and behavior differ from the real cloud.

Use on your local machine only. Keep the localhost binding; enable Docker access only for trusted local workloads.

Official implementation and supported APIs: https://github.com/floci-io/floci-az
