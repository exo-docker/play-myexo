# syntax=docker/dockerfile:1
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

# BuildKit cache mount for ~/.m2: persists across builds independently of the layer cache, so a pom.xml
# change (or a fresh builder with no cached layers at all, e.g. after a prune) only re-downloads the
# dependencies that actually changed instead of the entire repository.
COPY my-exo/pom.xml ./pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -q -B dependency:go-offline

COPY my-exo/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -q -B package -DskipTests

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-resolute
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

RUN apt-get -qq update && apt-get -qq install -y tini curl && apt-get -qq -y autoremove && \
    apt-get -qq -y clean && rm -rf /var/lib/apt/lists/*

# Pinned uid/gid 1000: logs/ is bind-mounted from a host directory owned by uid/gid 1000, so this must
# stay stable across base-image changes -- useradd's auto-assigned id shifts with however many system
# accounts the base image already has (1000 on jammy, 1001 on resolute since it ships a built-in
# "ubuntu" account at 1000), which silently breaks the host directory's ownership match. Removing that
# built-in account first to free up 1000 (no-ops harmlessly on bases that don't have one).
RUN (userdel -r ubuntu 2>/dev/null || true) && (groupdel ubuntu 2>/dev/null || true) \
    && useradd --create-home --user-group --uid 1000 --shell /bin/bash ${EXO_USER} \
    && mkdir -p ${MY_EXO_APPDIR}/conf ${MY_EXO_APPDIR}/logs && chown -R ${EXO_USER}:${EXO_GROUP} ${MY_EXO_DIR}

WORKDIR ${MY_EXO_APPDIR}

COPY --from=build --chown=${EXO_USER}:${EXO_GROUP} /build/target/my-exo-*.jar ${MY_EXO_APPDIR}/app.jar
COPY --chown=${EXO_USER}:${EXO_GROUP} play-myexo/start_My_eXo.sh ${MY_EXO_APPDIR}/start_My_eXo.sh
RUN chmod 775 ${MY_EXO_APPDIR}/start_My_eXo.sh

USER ${EXO_USER}

EXPOSE 20100

# spring-boot-starter-actuator is already a dependency; /actuator/health is permitAll'd in SecurityConfig
# specifically so this can reach it unauthenticated. start-period covers a cold JVM boot + Crowd/DB waits.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:20100/actuator/health || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./start_My_eXo.sh"]
