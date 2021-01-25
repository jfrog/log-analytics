# JFrog Log Analytics

This project integrates JFrog logs into various log analytic providers through the use of fluentd as a common logging agent.

The goal of this project is to provide JFrog customers with robust log analytic solutions that they could use to monitor the JFrog unified platform microservices.

## How to clone this project?

This project makes use of git submodules for this reason we recommend you clone with the --recursive flag to ensure all log vendor files are downloaded.

````bash
git clone https://github.com/jfrog/log-analytics.git --recursive
cd log-analytics
git submodule foreach git checkout master
git submodule foreach git pull origin master
````

## Table of Contents

   * [Fluentd](#fluentd)
     * [Root Installation](#root-installation)
     * [User Installation](#user-installation)
     * [Logger Agent](#logger-agent)
     * [Config Files](#config-files)
     * [Running As A Service](#running-as-a-service)
     * [Running As A Service As A Regular User](#running-as-a-service-as-a-regular-user)
   * [Splunk](https://github.com/jfrog/log-analytics-splunk/blob/master/README.md)
   * [Elasticsearch - Kibana](https://github.com/jfrog/log-analytics-elastic/blob/master/README.md)
   * [Prometheus-Grafana](https://github.com/jfrog/log-analytics-prometheus/blob/master/README.md)
   * [Datadog](https://github.com/jfrog/log-analytics-datadog/blob/master/README.md)
   * [Tools](#tools)
   * [Contributing](#contributing)
   * [Versioning](#versioning)
   * [Contact](#contact)

## Fluentd 

Fluentd is a required component to use this integration.

Fluentd has an logger agent called td-agent which will be required to be installed into each node you wish to monitor logs on.

For more details on how to install Fluentd into your environment please visit: [Fluentd installation guide] (https://docs.fluentd.org/installation) or read the steps provided in this document.
#### JFrog Installation Configurations

Due to the nature of customer installations varying we cannot account for all possible installations however to ensure our integration works with your installation please review:

[JFrog Product Directory Structure guide](https://www.jfrog.com/confluence/display/JFROG/System+Directories#SystemDirectories-JFrogProductDirectoryStructure)

The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location.

Helm based installs will already have this defined based upon the underlying docker images.

For non-k8s based installations below is a reference to the Docker image locations per product. Note these locations may be different based upon the installation location chosen.

````text
Artifactory: 
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/artifactory/
````

````text
Xray:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/xray/
````

````text
Mission Control:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/mc/
````

````text
Distribution:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/distribution/
````

````text
Pipelines:
export JF_PRODUCT_DATA_INTERNAL=/opt/jfrog/pipelines/var/
````

Note if you are using Artifactory 6.x you will need to use the legacy environment variable ARTIFACTORY_HOME instead.


## Fluentd Install

### OS / Virtual Machine

Recommended install is through fluentd's native OS based package installs:

| OS            | Package Manager | Link |
|---------------|-----------------|------|
| CentOS/RHEL   | RPM (YUM)       | https://docs.fluentd.org/installation/install-by-rpm |
| Debian/Ubuntu | APT             | https://docs.fluentd.org/installation/install-by-deb |
| MacOS/Darwin  | DMG             | https://docs.fluentd.org/installation/install-by-dmg |
| Windows       | MSI             | https://docs.fluentd.org/installation/install-by-msi |

Alternatively, it's also possible to use the shell script to install Fluentd as service (td-agent4, root access required):

| OS            | Package Manager | Link |
|---------------|-----------------|------|
| Linux (x86_64) Centos/Amazon| N/A             | https://raw.githubusercontent.com/jfrog/log-analytics/master/fluentd-installer/scripts/linux/fluentd-agent-installer.sh |

User installs can utilize the zip installer for Linux

| OS            | Package Manager | Link |
|---------------|-----------------|------|
| Linux (x86_64)| ZIP             | https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz |

Download it to a directory the user has permissions to write such as the `$JF_PRODUCT_DATA_INTERNAL` locations discussed above:

````text
cd $JF_PRODUCT_DATA_INTERNAL
wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz
````

Untar to create the folder:
````text
tar -xvf fluentd-1.11.0-linux-x86_64.tar.gz
````
Move into the new folder:

````text
cd fluentd-1.11.0-linux-x86_64
````
Run the fluentd wrapper with one argument pointed to the configuration file to load:

````text
./fluentd test.conf
````

Next steps are to setup a  `fluentd.conf` file using the relevant integrations for Splunk, DataDog, Elastic, or Prometheus.


### Docker

Recommended install for Docker is to utilize the zip installer for Linux

| OS            | Package Manager | Link |
|---------------|-----------------|------|
| Linux (x86_64)| ZIP             | https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz |

Download it to a directory the user has permissions to write such as the `$JF_PRODUCT_DATA_INTERNAL` locations discussed above:

````text
cd $JF_PRODUCT_DATA_INTERNAL
wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz
````

Untar to create the folder:
````text
tar -xvf fluentd-1.11.0-linux-x86_64.tar.gz
````
Move into the new folder:

````text
cd fluentd-1.11.0-linux-x86_64
````
Run the fluentd wrapper with one argument pointed to the configuration file to load:

````text
./fluentd test.conf
````

Next steps are to setup a  `fluentd.conf` file using the relevant integrations for Splunk, DataDog, Elastic, or Prometheus.

### Kubernetes

Recommended install for Kubernetes is to utilize the helm chart with the associated values.yaml in this repo.

| Product | Example Values File |
|---------|-------------|
| Artifactory | helm/artifactory-values.yaml |
| Artifactory HA | helm/artifactory-ha-values.yaml |
| Xray | helm/xray-values.yaml |
| Distribution | helm/distribution-values.yaml |
| Mission Control | helm/mission-control-values.yaml |
| Pipelines | helm/pipelines-values.yaml |

To modify existing Kubernetes based deployments without using Helm users can use the zip installer for Linux:

| OS            | Package Manager | Link |
|---------------|-----------------|------|
| Linux (x86_64)| ZIP             | https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz |

Download it to a directory the user has permissions to write such as the `$JF_PRODUCT_DATA_INTERNAL` locations discussed above:

````text
cd $JF_PRODUCT_DATA_INTERNAL
wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz
````

Untar to create the folder:
````text
tar -xvf fluentd-1.11.0-linux-x86_64.tar.gz
````
Move into the new folder:

````text
cd fluentd-1.11.0-linux-x86_64
````
Run the fluentd wrapper with one argument pointed to the configuration file to load:

````text
./fluentd test.conf
````

Next steps are to setup a  `fluentd.conf` file using the relevant integrations for Splunk, DataDog, Elastic, or Prometheus.

### User Installation

Non-root users to make life easier for we have provided a tar.gz containing everything you need to run fluentd.

Follow these steps:

* Download the tar from this Github: [fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz](fluentd-installer/fluentd-1.11.0-linux-x86_64.tar.gz)

* Explode the tar into $JF_PRODUCT_DATA_INTERNAL and run:

``` 
$JF_PRODUCT_DATA_INTERNAL/fluentd-1.11.0-linux-x86_64/fluentd <conf_file>
```

Updating fluentd to future releases is simple as well:

``` 
$JF_PRODUCT_DATA_INTERNAL/fluentd-1.11.0-linux-x86_64/lib/ruby/bin/gem install fluentd
```

Adding any fluentd plugins like Datadog as works in the same fashion:

``` 
$JF_PRODUCT_DATA_INTERNAL/fluentd-1.11.0-linux-x86_64/lib/ruby/bin/gem install fluent-plugin-datadog
```

### Root Installation

* Package Manager installations of td-agent only.

The default configuration file for td-agent is located at:

```
/etc/td-agent/td-agent.conf
```

You should update this configuration file and run td-agent as a service.

If you wish to only run td-agent against a test configuration file you can also run:

```
td-agent -c fluentd.conf
```

If Fluentd was installed with [fluentd-agent-installer.sh](https://raw.githubusercontent.com/jfrog/log-analytics/master/fluentd-installer/scripts/linux/fluentd-agent-installer.sh) this step can be skipped. Once td-agent has been installed on an Artifactory or Xray node you will also need to install the relevant plugin if you are using Splunk or Datadog:

Splunk:
```
td-agent-gem install fluent-plugin-splunk-enterprise
```

Datadog:
``` 
td-agent-gem install fluent-plugin-datadog
```

Elastic:
``` 
td-agent-gem install fluent-plugin-elasticsearch
```

## Fluentd Configuration

The following sections will cover how you can configure fluentd once it has been installed.

### Config Files

Fluentd requires configuration file to know which logs to tail and how to ship them to the correct log provider.

Our configurations are saved into each log provider's folder.

We will need to store these configurations into the correct location per our installer type.

The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location.

Helm based installs will already have this defined based upon the underlying docker images.

For non-k8s based installations below is a reference to the Docker image locations per product. Note these locations may be different based upon the installation location chosen.

````text
Artifactory: 
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/artifactory/
````

````text
Xray:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/xray/
````

````text
Mision Control:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/mc/
````

````text
Distribution:
export JF_PRODUCT_DATA_INTERNAL=/var/opt/jfrog/distribution/
````

````text
Pipelines:
export JF_PRODUCT_DATA_INTERNAL=/opt/jfrog/pipelines/var/
````

If you are running on RT 6.x you will need to ensure the ARTIFACTORY_HOME environment variable is set instead.

### Running as a service

If Fluentd was installed with [fluentd-agent-installer.sh](https://raw.githubusercontent.com/jfrog/log-analytics/master/fluentd-installer/scripts/linux/fluentd-agent-installer.sh) this step can be omitted. By default td-agent will run as the td-agent user however the JFrog logs folder only has file permissions for the artifactory or xray user.

* Fix the group and file permissions issue in Artifactory as root:

``` 
usermod -a -G artifactory td-agent
chmod 0770 $JF_PRODUCT_DATA_INTERNAL/log
chmod 0640 $JF_PRODUCT_DATA_INTERNAL/log/*.log
```

* Fix the group and file permissions issue in Xray as root:

``` 
usermod -a -G xray td-agent
chmod 0770 $JF_PRODUCT_DATA_INTERNAL/log
chmod 0640 $JF_PRODUCT_DATA_INTERNAL/log/*.log
```

* Run td-agent and check it's status

```
systemctl start td-agent
systemctl status td-agent
```

### Running as a service as a regular user

Using systemd:

* Create a service unit configuration file

```
mkdir -p ~/.config/systemd/user/
touch ~/.config/systemd/user/jfrogfluentd.service
```

* Copy paste below snippet, update the path to match $JF_PRODUCT_DATA_INTERNAL/ and fluentd configuration file location, and save into the file:

```
[Unit]
Description=JFrog_Fluentd

[Service]
ExecStart=/opt/jfrog/artifactory/var/fluentd-1.11.0-linux-x86_64/fluentd <conf_file>
Restart=always

[Install]
WantedBy=graphical.target
See man systemd.service and man systemd.unit for more options.
```

* Enable service in userspace

``` 
systemctl --user enable jfrogfluentd
```

* Start it and check it's status

```
systemctl --user start jfrogfluentd
systemctl --user status jfrogfluentd
```

* Enjoy!

## Tools
* [Fluentd](https://www.fluentd.org) - Fluentd Logging Aggregator/Agent
* [Splunk](https://www.splunk.com/) - Splunk Logging Platform
* [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) - Splunk HEC used to upload data into Splunk
* [Elasticsearch](https://www.elastic.co/) - Elastic search log data platform
* [Kibana](https://www.elastic.co/kibana) - Elastic search visualization layer
* [Prometheus](https://prometheus.io/) - Prometheus metrics and monitoring
## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Contact
* Github
