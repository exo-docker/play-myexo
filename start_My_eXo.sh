#!/bin/bash -ue

#wait until the database is ready
sleep 10


if [ "$APP_MODE" = "preprod" ]; then
  #apply evolutions on database schema
  play evolutions:apply --%preprod
  #run app
  play start --%preprod -Xmx1g -Xms1g
else  
  play start --%prod -Xmx1g -Xms1g
fi

tail -f /dev/null
