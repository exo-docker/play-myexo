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

exec java -Xmx1g -Xms1g -jar app.jar --spring.profiles.active="${APP_MODE}"
