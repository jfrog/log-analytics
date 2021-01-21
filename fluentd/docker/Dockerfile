# Dockerfile for bitnami/fluentd sidecar image with all the necessary plugins for our log analytic providers
FROM bitnami/fluentd:1.12.0
LABEL maintainer "Partner Engineering <partner_support@jfrog.com>"

USER root
## Install custom Fluentd plugins
RUN fluent-gem install fluent-plugin-splunk-enterprise
RUN fluent-gem install fluent-plugin-datadog
RUN fluent-gem install fluent-plugin-elasticsearch

USER 1001