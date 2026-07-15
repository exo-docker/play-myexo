# play-myexo

Docker wrapper for [my-exo](https://github.com/exoplatform/my-exo), a Spring Boot (Java 21) HR/IT
management app. Runs the jar as a slim, non-root container.

## How to build

The image carries no application code of its own — no `my-exo` checkout is needed to build it. On
every container start, `start_My_eXo.sh` downloads the jar from `$MYEXO_JAR_URL` (e.g. a Nexus-hosted
build artifact) before launching it. This means a new my-exo release never requires rebuilding or
repushing this image: publish the new jar and point `MYEXO_JAR_URL` at it (or just restart the
container, if the URL is a stable "latest"-style pointer).

**Quick way** — from within `play-myexo/`:

```sh
./build.sh
```

This just wraps `docker buildx build ... --load`, tagging the result `exoplatform/my-exo:latest` and
loading it into your local `docker images` for a single-platform build. Uses `buildx` throughout — the
legacy `docker build` builder is never used.

**Manual way** (multi-arch, matching how the real `exoplatform/play-myexo` image is built) — from
within `play-myexo/`:

```sh
docker buildx build --builder <your-builder> \
  --platform linux/amd64,linux/arm64 \
  -t exoplatform/play-myexo:<tag> \
  .
```

Add `--push` to push the result, or `--load` to pull a single-platform build into your local `docker
images` for inspection (`--load` doesn't support multiple `--platform` values at once).

## Running

`MYEXO_JAR_URL` is required — the container fails fast at startup if it's unset:

```sh
docker run -d --name=my-exo -p 20100:20100 \
  -e MYEXO_JAR_URL=https://nexus.example.com/repository/my-exo/my-exo-2.0.0.jar \
  exoplatform/my-exo:latest
```

## Configuration

See [`conf/README.md`](conf/README.md) for the environment variables the image reads (DB/SMTP
connection settings, JVM heap, etc.) and how to mount config overrides without rebuilding.

## Validating the image

[`goss.yaml`](goss.yaml) has structural checks (correct uid/gid, Java version, `curl` installed for
the healthcheck) runnable with [dgoss](https://github.com/goss-org/goss):

```sh
GOSS_PATH=/path/to/goss GOSS_FILES_PATH=. dgoss run --entrypoint bash exoplatform/my-exo:latest -c "sleep 300"
```

These don't require a database, and don't cover the jar download (that entrypoint isn't run under the
invocation above) — for an actual end-to-end boot check, run the image inside a real compose stack
(with `db` and `smtp` reachable, and `MYEXO_JAR_URL` pointing at a real jar) and hit `/actuator/health`.
