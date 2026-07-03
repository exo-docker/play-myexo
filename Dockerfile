# Builds and runs the my-exo Spring Boot application (replaces the Play 1.x runtime this image used to bootstrap).
#
# This Dockerfile expects `my-exo` and `play-myexo` checked out as sibling directories, and must be built with
# the build context set to their *parent* directory so the build stage can see the my-exo source tree:
#
#   Build: docker build -f play-myexo/Dockerfile -t exoplatform/my-exo:latest .          (run from the parent dir)
#          or simply: ./build.sh                                                        (from within play-myexo/)
#   Run:   docker run -d --name=my-exo -p 20100:20100 exoplatform/my-exo:latest
#          docker run -d --name=my-exo -p 20100:20100 -e APP_MODE=preprod exoplatform/my-exo:latest

# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Cache dependency resolution separately from source changes.
COPY my-exo/pom.xml ./pom.xml
RUN mvn -q -B dependency:go-offline

COPY my-exo/src ./src
RUN mvn -q -B package -DskipTests

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-jammy
LABEL maintainer="eXo <exo+docker@exoplatform.com>"

ENV MY_EXO_DIR=/opt/myexo
ENV MY_EXO_APPDIR=/opt/myexo/code
ENV APP_MODE=prod
ENV EXO_USER=myexo
ENV EXO_GROUP=myexo
# Mount an application.yml/application-<profile>.yml here to override baked-in settings without rebuilding
# the image (replaces the old bind-mounted conf/application.conf convention). Absent by default: `optional:`
# means Spring Boot silently skips it if nothing is mounted.
ENV SPRING_CONFIG_ADDITIONAL_LOCATION=optional:file:${MY_EXO_APPDIR}/conf/

RUN apt-get -qq update && apt-get -qq install -y tini && apt-get -qq -y autoremove && \
    apt-get -qq -y clean && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --user-group --shell /bin/bash ${EXO_USER} \
    && mkdir -p ${MY_EXO_APPDIR}/conf && chown -R ${EXO_USER}:${EXO_GROUP} ${MY_EXO_DIR}

WORKDIR ${MY_EXO_APPDIR}

COPY --from=build --chown=${EXO_USER}:${EXO_GROUP} /build/target/my-exo-*.jar ${MY_EXO_APPDIR}/app.jar
COPY --chown=${EXO_USER}:${EXO_GROUP} play-myexo/start_My_eXo.sh ${MY_EXO_APPDIR}/start_My_eXo.sh
RUN chmod 775 ${MY_EXO_APPDIR}/start_My_eXo.sh

USER ${EXO_USER}

EXPOSE 20100

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./start_My_eXo.sh"]
