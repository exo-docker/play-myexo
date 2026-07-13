# play-myexo

Docker wrapper for [my-exo](https://github.com/exoplatform/my-exo), a Spring Boot (Java 21) HR/IT
management app. Builds the jar from source and runs it as a slim, non-root container.

## How to build

This repo expects `my-exo` and `play-myexo` checked out as **sibling directories**, and must be built
with the build context set to their *parent* directory, so the build stage can see the `my-exo` source
tree:

```
parent-dir/
├── my-exo/
└── play-myexo/
```

**Quick way** — from within `play-myexo/`:

```sh
./build.sh
```

This just wraps the equivalent `docker build` command below, run from the parent directory, tagging
the result `exoplatform/my-exo:latest`.

**Manual way** (multi-arch, matching how the real `exoplatform/play-myexo` image is built) — from the
parent directory:

```sh
docker buildx build --builder <your-builder> \
  --platform linux/amd64,linux/arm64 \
  -f play-myexo/Dockerfile \
  -t exoplatform/play-myexo:<tag> \
  .
```

Add `--push` to push the result, or `--load` to pull a single-platform build into your local `docker
images` for inspection (`--load` doesn't support multiple `--platform` values at once).

The Dockerfile is a two-stage build: a Maven stage compiles `my-exo` from source (using a BuildKit
cache mount for `~/.m2`, so a `pom.xml` change or a fresh builder doesn't re-download the entire
dependency tree), and a slim `eclipse-temurin` JRE stage runs the resulting jar via `java -jar`. Only
the compiled jar crosses into the final image — no source code, no `pom.xml`, no build tooling.

## Configuration

See [`conf/README.md`](conf/README.md) for the environment variables the image reads (DB/SMTP
connection settings, JVM heap, etc.) and how to mount config overrides without rebuilding.

## Validating the image

[`goss.yaml`](goss.yaml) has structural checks (jar present, correct uid/gid, Java version, `curl`
installed for the healthcheck) runnable with [dgoss](https://github.com/goss-org/goss):

```sh
GOSS_PATH=/path/to/goss GOSS_FILES_PATH=. dgoss run --entrypoint bash exoplatform/my-exo:latest -c "sleep 300"
```

These don't require a database — for an actual end-to-end boot check, run the image inside a real
compose stack (with `db` and `smtp` reachable) and hit `/actuator/health`.
