# MongoDB

Run `./start.sh`. MongoDB 8 listens on `localhost:27017`; `developer` is a root administrator. The generated password is in `.env` (excluded from Git). Connect with MongoDB Compass or mongosh, using authentication database `admin`. Your application database can be `app`; MongoDB creates it on the first write.

From a development container attached to `dev-services`, use host `mongodb`, port `27017`, username `developer`, password from `.env`, and `authSource=admin`.

`docker compose stop` stops it; `./start.sh` resumes it. `docker compose down` preserves the named data volume; adding `--volumes` permanently deletes its data. Credentials initialize only on a fresh volume. Change existing passwords through MongoDB before updating `.env`.

Use on your local machine only. Keep the localhost port binding. Override `SERVICE_IMAGE` or `SERVICE_PORT` in `.env` if needed.
