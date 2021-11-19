# syntax=docker/dockerfile:1
# use Docker BuildKit to pass secret into build container
# https://docs.docker.com/develop/develop-images/build_enhancements/

FROM releases-docker.jfrog.io/jfrog/artifactory-pro AS BUILD_IMAGE

WORKDIR /usr/observability/

COPY ./fluentd-agent-installer.sh ./
COPY ./*.conf ./

EXPOSE 8082

CMD ["/usr/observability/fluentd-agent-installer.sh"]
