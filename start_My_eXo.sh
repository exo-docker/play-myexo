#!/bin/bash -ue

# Wait until the database is reachable. HikariCP will also retry internally, but failing fast on a cold
# start (e.g. `docker compose up` bringing the DB and app containers up together) is a bad first impression.
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
for i in $(seq 1 30); do
  if (exec 3<>"/dev/tcp/${DB_HOST}/${DB_PORT}") 2>/dev/null; then
    exec 3<&- 3>&-
    break
  fi
  echo "Waiting for database at ${DB_HOST}:${DB_PORT}... (${i}/30)"
  sleep 2
done

# Overridable via the myexo service's environment: in docker-compose (see puppet-config), or a plain
# `docker run -e JAVA_XMX=4g`. Defaults match what was previously hardcoded.
JAVA_XMX="${JAVA_XMX:-2g}"
JAVA_XMS="${JAVA_XMS:-1g}"
JAVA_OPTS="${JAVA_OPTS:-}"

echo "Starting my-exo (profile=${APP_MODE}) with JAVA_XMX=${JAVA_XMX} JAVA_XMS=${JAVA_XMS} JAVA_OPTS=${JAVA_OPTS:-<none>}"

# JAVA_OPTS deliberately left unquoted: it may hold several space-separated flags that need to split.
exec java -Xmx"${JAVA_XMX}" -Xms"${JAVA_XMS}" ${JAVA_OPTS} -jar app.jar --spring.profiles.active="${APP_MODE}"
