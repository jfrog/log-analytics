## Automation to setup Artifactory from Scratch on RedHat

JFrog is supported on CentOS/RHEL 7 and above. You will need `sudo` permissions for many of the steps below.

On your RHEL 7+ installation ensure you have wget installed.

```
yum install wget
```
## Install Artifactory using yum

https://www.jfrog.com/confluence/display/JFROG/Installing+Artifactory#InstallingArtifactory-RPMInstallation

```
wget https://releases.jfrog.io/artifactory/artifactory-pro-rpms/artifactory-pro-rpms.repo -O jfrog-artifactory-pro-rpms.repo;
sudo mv jfrog-artifactory-pro-rpms.repo /etc/yum.repos.d/;
sudo yum update && sudo yum install jfrog-artifactory-pro
```

For Artifactory JF_PRODUCT_HOME is  `/opt/jfrog/artifactory`
logs will be in `/opt/jfrog/artifactory/var/log` or `/var/opt/jfrog/artifactory/log`

### Start Artifactory

```
sudo service artifactory start
## Run tail to ensure that console.log shows success messages
tail -F $JFROG_HOME/artifactory/var/log/console.log #$JFROG_HOME is usually same as $JF_PRODUCT_HOME as specified above.
```

## Install fluentd
```
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/artifactory/
cd $JF_PRODUCT_DATA_INTERNAL
wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz
tar -xvf fluentd-1.11.0-linux-x86_64.tar.gz

cd fluentd-1.11.0-linux-x86_64
```
### Download the configuration file to stream logs to Datadog

```
cd $JF_PRODUCT_DATA_INTERNAL
curl https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/fluent.conf.rt  --output fluet.conf.rt
```
Override the match directive(last section) of the downloaded fluent.conf.rt with the details given below
```
<match jfrog.**>
  @type datadog
  @id datadog_agent_jfrog_artifactory
  api_key API_KEY
  include_tag_key true
  dd_source fluentd
</match>
```
required: API_KEY is the apiKey from Datadog

dd_source attribute is set to the name of the log integration in your logs in order to trigger the integration automatic setup in datadog.

include_tag_key defaults to false and it will add fluentd tag in the json record if set to true

### Start fluentd with fluent config

```
sudo $JF_PRODUCT_DATA_INTERNAL/fluentd-1.11.0-linux-x86_64/fluentd $JF_PRODUCT_DATA_INTERNAL/fluent.conf.rt
```

You should start seeing logs appear under Logs section in Datadog. 