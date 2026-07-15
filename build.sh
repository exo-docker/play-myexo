#!/bin/bash -e
# Builds the my-exo Docker image. No my-exo source checkout needed: the image carries no application
# code of its own -- it's downloaded by start_My_eXo.sh from $MYEXO_JAR_URL on every container start.

cd "$(dirname "$0")"

# --load only supports a single platform (the local host's), so this is deliberately fast and
# single-arch -- it's meant for local testing, not the real release artifact. For the actual
# multi-arch (amd64+arm64) build that gets pushed, see the manual buildx command in README.md.
echo "Building exoplatform/my-exo:latest for the local host platform only ($(docker version -f '{{.Server.Os}}/{{.Server.Arch}}')) -- see README.md for the multi-arch --push build."
docker buildx build -t exoplatform/my-exo:latest --load .
