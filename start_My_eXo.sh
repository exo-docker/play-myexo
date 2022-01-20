#!/bin/bash -ue

#wait until the database is ready
sleep 10


if [ "$APP_MODE" = "preprod" ]; then
  #apply evolutions on database schema
  play evolutions:apply --%preprod
  #run app
  play run --%preprod -Xmx512m -Xms512m -XX:PermSize=128M -XX:MaxPermSize=512M
else
  play run -Xmx512m -Xms512m -XX:PermSize=128M -XX:MaxPermSize=512M
fi
