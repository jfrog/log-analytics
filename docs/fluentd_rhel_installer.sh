#! /usr/bin/bash

sudo yum install wget
wget https://releases.jfrog.io/artifactory/artifactory-pro-rpms/artifactory-pro-rpms.repo -O jfrog-artifactory-pro-rpms.repo;
sudo mv jfrog-artifactory-pro-rpms.repo /etc/yum.repos.d/;
sudo yum update && sudo yum install jfrog-artifactory-pro

sudo systemctl start artifactory.service

export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/artifactory/
cd $JF_PRODUCT_DATA_INTERNAL
sudo wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz
tar -xvf fluentd-1.11.0-linux-x86_64.tar.gz

cd $JF_PRODUCT_DATA_INTERNAL
curl https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/fluent.conf.rt  --output fluent.conf.rt
sudo $JF_PRODUCT_DATA_INTERNAL/fluentd-1.11.0-linux-x86_64/fluentd $JF_PRODUCT_DATA_INTERNAL/fluent.conf.rt
