# Dockerfile for bitnami/fluentd sidecar image with all the necessary plugins for our log analytic providers
FROM bitnami/fluentd:1.17.0
LABEL maintainer="Partner Engineering <partner_support@jfrog.com>"

## Build time Arguments, short circuit them to ENV Variables so they are available at run time also
ARG TARGET=TARGET_PLATFORM
ARG FLUENTD_CONF_LOCATION=FLUENTD_CONF_LOCATION

## Environment Variables set by this docker file, there will be seperate env params set by a env file while running the containers
## For better maintainability always depend dockerfile code on the environment variables declared in this file to add more platforms
ENV TGT_PLATFORM=$TARGET

USER root

## Install JFrog Plugins
RUN fluent-gem install fluent-plugin-concat
RUN fluent-gem install fluent-plugin-jfrog-siem
RUN fluent-gem install fluent-plugin-jfrog-metrics
RUN if [ "$TGT_PLATFORM" = "SPLUNK" ] ; then fluent-gem install fluent-plugin-splunk-hec; fi
RUN if [ "$TGT_PLATFORM" = "NEWRELIC" ] ; then fluent-gem install fluent-plugin-newrelic; fi
RUN if [ "$TGT_PLATFORM" = "DATADOG" ] ; then fluent-gem install fluent-plugin-datadog; fi
RUN if [ "$TGT_PLATFORM" = "NEWRELIC" ] || [ "$TGT_PLATFORM" = "DATADOG" ] ; then fluent-gem install fluent-plugin-jfrog-send-metrics; fi

# Install prerequisites
RUN apt-get update && apt-get install -y curl
CMD /bin/bash

# Copy the fluentd.conf file 
COPY $FLUENTD_CONF_LOCATION /opt/bitnami/fluentd/conf/fluentd.conf

ENTRYPOINT if [ -n "$TGT_PLATFORM" ] ; then cat /opt/bitnami/fluentd/conf/fluentd.conf; fluentd -v -c /opt/bitnami/fluentd/conf/fluentd.conf; fi

USER 1001

STOPSIGNAL SIGTERM