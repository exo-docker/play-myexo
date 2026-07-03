#!/bin/bash -e
# Builds the my-exo Docker image. Assumes `my-exo` and `play-myexo` are checked out as sibling directories
# (matches this repo's own layout expectations — see the Dockerfile header for details).

cd "$(dirname "$0")/.."

if [ ! -d "my-exo" ]; then
  echo "Expected a sibling 'my-exo' checkout at $(pwd)/my-exo — clone it there first." >&2
  exit 1
fi

docker build -f play-myexo/Dockerfile -t exoplatform/my-exo:latest .
