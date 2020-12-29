# JFrog Log Analytics

This project integrates JFrog logs into various log analytic providers through the use of fluentd as a common logging agent.

The goal of this project is to provide JFrog customers with robust log analytic solutions that they could use to monitor the JFrog unified platform microservices.

## How to clone this project?

This project makes use of git submodules for this reason we recommend you clone with the --recursive flag to ensure all log vendor files are downloaded.

Followed by using the --remote flag in the git submodule update command to pull the latest changes.

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
   * [Splunk](log-vendors/splunk/README.md)
   * [Elasticsearch - Kibana](log-vendors/elastic-fluentd-kibana/README.md)
   * [Prometheus-Grafana](log-vendors/prometheus-fluentd-grafana/README.md)
   * [Datadog](log-vendors/datadog/README.md)
   * [Tools](#tools)
   * [Contributing](#contributing)
   * [Versioning](#versioning)
   * [Contact](#contact)

## Fluentd 

Fluentd is a required component to use this integration.

Fluentd has an logger agent called td-agent which will be required to be installed into each node you wish to monitor logs on.

For more details on how to install Fluentd into your environment please visit:

[Fluentd installation guide](https://docs.fluentd.org/installation)

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

Note if you are using Artifactory 6.x you will need to use the legacy environment variable ARTIFACTORY_HOME instead.

#### Root Installation

Install the td-agent agent on Redhat UBI we need to run the below command:

```
$ curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh
```

Root access will be required as this will use yum to install td-agent

#### User Installation

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

#### Logger Agent

* Package Manager installations only.

The default configuration file for td-agent is located at:

```
/etc/td-agent/td-agent.conf
```

You should update this configuration file and run td-agent as a service.

If you wish to only run td-agent against a test configuration file you can also run:

```
td-agent -c fluentd.conf
```

Once td-agent has been installed on an Artifactory or Xray node you will also need to install the relevant plugin if you are using Splunk or Datadog:

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

#### Config Files

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

#### Running as a service

By default td-agent will run as the td-agent user however the JFrog logs folder only has file permissions for the artifactory or xray user.

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

#### Running as a service as a regular user

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
