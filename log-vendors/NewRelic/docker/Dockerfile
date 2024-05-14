# Dockerfile for bitnami/fluentd sidecar image with all the necessary plugins for our log analytic providers
FROM bitnami/fluentd:1.15.2
LABEL maintainer="Partner Engineering <partner_support@jfrog.com>"

## Build time Arguments, short circuit them to ENV Variables so they are available at run time also
ARG SOURCE=JFRT
ARG TARGET=NEWRELIC

## Environment Variables set by this docker file, there will be seperate env params set by a env file while running the containers
## For better maintainability always depend dockerfile code on the environment variables declared in this file to add more platforms
ENV SRC_PLATFORM=$SOURCE
ENV TGT_PLATFORM=$TARGET

USER root

## Install JFrog Plugins
RUN fluent-gem install fluent-plugin-newrelic
RUN fluent-gem install fluent-plugin-jfrog-siem
RUN fluent-gem install fluent-plugin-jfrog-metrics
RUN fluent-gem install fluent-plugin-jfrog-send-metrics

# Install prerequisites
RUN apt-get update && apt-get install -y curl
CMD /bin/bash


## Download Config Files
RUN if [ "$SRC_PLATFORM" = "JFRT" ] ; then echo "Downloading the fluentd config file for $SRC_PLATFORM and $TGT_PLATFORM "; curl https://raw.githubusercontent.com/jfrog/log-analytics-newrelic/master/fluent.conf.rt -o /opt/bitnami/fluentd/conf/fluentd.conf; else echo "Not Downloading"; fi
RUN if [ "$SRC_PLATFORM" = "JFXRAY" ] ; then echo "Downloading the fluentd config file for $SRC_PLATFORM and $TGT_PLATFORM "; curl https://raw.githubusercontent.com/jfrog/log-analytics-newrelic/master/fluent.conf.xray -o /opt/bitnami/fluentd/conf/fluentd.conf; else echo "Not Downloading"; fi


ENTRYPOINT if [ "$TGT_PLATFORM" = "NEWRELIC" ] ; then cat /opt/bitnami/fluentd/conf/fluentd.conf; fluentd -v -c /opt/bitnami/fluentd/conf/fluentd.conf; fi


USER 1001

STOPSIGNAL SIGTERM