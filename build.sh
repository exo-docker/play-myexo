#!/bin/bash -e
# Builds the my-exo Docker image. Assumes `my-exo` and `play-myexo` are checked out as sibling directories
# (matches this repo's own layout expectations — see the Dockerfile header for details).

cd "$(dirname "$0")/.."

if [ ! -d "my-exo" ]; then
  echo "Expected a sibling 'my-exo' checkout at $(pwd)/my-exo — clone it there first." >&2
  exit 1
fi

# --load only supports a single platform (the local host's), so this is deliberately fast and
# single-arch -- it's meant for local testing, not the real release artifact. For the actual
# multi-arch (amd64+arm64) build that gets pushed, see the manual buildx command in README.md.
echo "Building exoplatform/my-exo:latest for the local host platform only ($(docker version -f '{{.Server.Os}}/{{.Server.Arch}}')) -- see README.md for the multi-arch --push build."
docker buildx build -f play-myexo/Dockerfile -t exoplatform/my-exo:latest --load .
