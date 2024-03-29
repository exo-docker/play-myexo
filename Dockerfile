# Deploy play in docker image based on eXo jdk image
# some dependencies are deployed for my-exo apps need
# This image is used for myexo application
# It is based on this work: https://github.com/exoplatform/my-exo/blob/develop/envdev/docker/my-exo-web/Dockerfile
# Build: docker build -t exoplatform/play-myexo .
# Run:      docker run -ti --rm --name=play-myexo -p 9000:9000 exoplatform/play-myexo
#           docker run -d --name=play-myexo -p 9000:9000 exoplatform/play-myexo
FROM       exoplatform/jdk:openjdk-8-ubuntu-2204
LABEL maintainer="eXo <exo+docker@exoplatform.com>"

# Environment variables
ENV MY_EXO_DIR /opt/myexo
ENV MY_EXO_APPDIR /opt/myexo/code
ENV MY_EXO_PLAYDIR /opt/play

ENV PLAY_VERSION 1.3.0
ENV APP_MODE prod

ENV EXO_USER myexo
ENV EXO_GROUP myexo

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN useradd --create-home --user-group --shell /bin/bash ${EXO_USER} \
   && apt-get -qq update && apt-get -qq -y upgrade ${_APT_OPTIONS} && apt-get -qq install -y sudo ant python2 && apt-get -qq -y autoremove && \
  apt-get -qq -y clean && \
  rm -rf /var/lib/apt/lists/*

# Create needed directories
RUN mkdir -p ${MY_EXO_APPDIR} && chown ${EXO_USER}:${EXO_GROUP} ${MY_EXO_APPDIR} \
    && mkdir -p ${MY_EXO_APPDIR}/conf && chown ${EXO_USER}:${EXO_GROUP} ${MY_EXO_APPDIR}/conf \
    && mkdir -p ${MY_EXO_PLAYDIR} && chown ${EXO_USER}:${EXO_GROUP} ${MY_EXO_PLAYDIR}


WORKDIR ${MY_EXO_APPDIR}
# copy default application.conf
COPY conf/application.conf ${MY_EXO_APPDIR}/conf/application.conf
# Add script to start my-exo app
COPY start_My_eXo.sh ${MY_EXO_APPDIR}/start_My_eXo.sh
RUN chmod 775 ${MY_EXO_APPDIR}/start_My_eXo.sh \
    && chown -R ${EXO_USER}:${EXO_GROUP} . \
    && chown -R ${EXO_USER}:${EXO_GROUP} /opt

RUN install /usr/bin/python2 /usr/bin/python

# Install Play Framework
USER myexo

RUN cd ${MY_EXO_PLAYDIR} && \
    curl -L -o play-${PLAY_VERSION}.zip http://downloads.typesafe.com/play/${PLAY_VERSION}/play-${PLAY_VERSION}.zip && \
    unzip -q play-${PLAY_VERSION}.zip && rm play-${PLAY_VERSION}.zip  && \
    chmod +x ${MY_EXO_PLAYDIR}/play1-${PLAY_VERSION}/play

USER root
RUN ln -sf ${MY_EXO_PLAYDIR}/play1-${PLAY_VERSION}/play /usr/local/bin

USER myexo

#Download play dependencies
COPY dependencies.yml conf/dependencies.yml
RUN play dependencies --sync && \
    rm -rf conf/dependencies.yml

EXPOSE 20100
ENTRYPOINT ["/usr/local/bin/tini", "--"]
CMD ${MY_EXO_APPDIR}/start_My_eXo.sh
