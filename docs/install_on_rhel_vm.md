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
sudo service artifactory start|stop|status
## Run tail to ensure that console.log shows success messages
tail -F $JFROG_HOME/artifactory/var/log/console.log #$JFROG_HOME is usually same as $JF_PRODUCT_HOME as specified above.
```

## Install td-agent as specified
```
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/artifactory/data

curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
```

## Install the gem to support Datadog
```
td-agent-gem install fluent-plugin-datadog
```
###### @Mahitha - I have not tested the steps below yet.

## Download the configuration file to stream logs to Datadog

```
cd $JF_PRODUCT_DATA_INTERNAL
curl https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/fluent.conf.rt  --output fluet.conf.rt
```

## Start td-agent with fluent config

```

```