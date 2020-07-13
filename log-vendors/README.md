# JFrog Log Vendors

This project has information about various log-vendors like splunk, datadog, elastic and prometheus. 

To build artifactory and xray images with fluentd installed and log-vendor configuration setup, use build arguments with the correct version of Artifactory and path to the respective fluentd configuration: 

```--build-arg ARTIFACTORY_BASE_VERSION=${LATEST_VERSION} --build-arg FLUENT_CONF=${PATH_TO_FLUENT_CONF}```

Example:
 
```docker build -f Dockerfile.redhat-ubi-rt7-fluentd --build-arg ARTIFACTORY_BASE_VERSION={LATEST_VERSION} --build-arg FLUENT_CONF=splunk/fluent.conf.rt -t {IMAGE_NAME} .```

Versions of Artifactory: 
https://bintray.com/jfrog/reg2/jfrog%3Aartifactory-pro


