#!/bin/bash -ue

# The image ships with no application jar baked in -- fetched fresh on every container start from a
# published build artifact (e.g. Nexus), so a new my-exo release never requires rebuilding/repushing
# this image; only publishing a new jar and pointing MYEXO_JAR_URL at it (or restarting the container,
# if the URL is a stable "latest"-style pointer).
#
# Dev convenience: mount a jar directly at this path (e.g. -v ./my-exo.jar:/opt/myexo/code/app.jar) to
# skip the download entirely and run that jar instead -- no MYEXO_JAR_URL/network access needed.
if [ -f app.jar ]; then
  echo "app.jar already present (mounted), skipping download."
else
  : "${MYEXO_JAR_URL:?MYEXO_JAR_URL must be set to the download URL for the my-exo jar}"
  echo "Downloading my-exo jar from ${MYEXO_JAR_URL}..."
  # MYEXO_JAR_AUTHORIZATION is optional -- the full value of the Authorization header to send (e.g.
  # "Bearer <token>"), needed for a private repository (e.g. Nexus) that requires one to download from.
  if [ -n "${MYEXO_JAR_AUTHORIZATION:-}" ]; then
    curl -fsSL -H "Authorization: ${MYEXO_JAR_AUTHORIZATION}" -o app.jar "${MYEXO_JAR_URL}"
  else
    curl -fsSL -o app.jar "${MYEXO_JAR_URL}"
  fi
  echo "Downloaded app.jar ($(du -h app.jar | cut -f1))"
fi

# Wait until the database is reachable. HikariCP will also retry internally, but failing fast on a cold
# start (e.g. `docker compose up` bringing the DB and app containers up together) is a bad first impression.
# Same MYEXO_DB_HOST/MYEXO_DB_PORT names the app's own datasource URL uses (application.yml), so one
# override controls both the wait-loop and the actual JDBC connection.
MYEXO_DB_HOST="${MYEXO_DB_HOST:-db}"
MYEXO_DB_PORT="${MYEXO_DB_PORT:-3306}"
for i in $(seq 1 30); do
  if (exec 3<>"/dev/tcp/${MYEXO_DB_HOST}/${MYEXO_DB_PORT}") 2>/dev/null; then
    exec 3<&- 3>&-
    break
  fi
  echo "Waiting for database at ${MYEXO_DB_HOST}:${MYEXO_DB_PORT}... (${i}/30)"
  sleep 2
done

# Overridable via the myexo service's environment: in docker-compose (see puppet-config), or a plain
# `docker run -e MYEXO_JAVA_XMX=4g`. Defaults match what was previously hardcoded.
MYEXO_JAVA_XMX="${MYEXO_JAVA_XMX:-2g}"
MYEXO_JAVA_XMS="${MYEXO_JAVA_XMS:-1g}"
MYEXO_JAVA_OPTS="${MYEXO_JAVA_OPTS:-}"

echo "Starting my-exo (profile=${APP_MODE}) with MYEXO_JAVA_XMX=${MYEXO_JAVA_XMX} MYEXO_JAVA_XMS=${MYEXO_JAVA_XMS} MYEXO_JAVA_OPTS=${MYEXO_JAVA_OPTS:-<none>}"

# MYEXO_JAVA_OPTS deliberately left unquoted: it may hold several space-separated flags that need to split.
exec java -Xmx"${MYEXO_JAVA_XMX}" -Xms"${MYEXO_JAVA_XMS}" ${MYEXO_JAVA_OPTS} -jar app.jar --spring.profiles.active="${APP_MODE}"
