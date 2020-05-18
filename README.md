# JFrog Log Analytics
This project integrates Jfrog logs into various log analytic providers through the use of fluentd as a common logging agent.
The goal of this project is to provide Jfrog customers with robust log analytic solutions that they could use to monitor the Jfrog unified platform microservices.

## Table of Contents

   * [Fluentd Setup](#fluentd-setup)
   * [Fluentd Config](#fluentd-setup)
   * [Splunk](#splunk)
     * [Demo](#demo)
   * [Running Fluentd](#running-fluentd)
   * [Tools](#tools)
   * [Contributing](#contributing)
   * [Versioning](#versioning)
   * [Contact](#contact)

## Fluentd Setup

Fluentd is required component to use the Jfrog log analytics integration.

For more details on how to install fluentd into your environment please visit:

[Fluentd installation guide](https://docs.fluentd.org/installation)

Fluentd has an agent called td-agent which will be required to be installed into each node you wish to monitor logs on.

In our example we will be using Redhat UBI.

We find for Redhat to install the fluentd agent called “td-agent” we need to run the below command:

```
$ curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent3.sh | sh
```

Root access will be required as this will use yum to install td-agent

There are options on how to install td-agent as non-root user such as:

``` 
Ruby + gem install guide
Dpkg -X / Rpm2cpio variants to explode package contents into user space
```

In general it will be easier to use the relevant package manager such as yum or apt if possible.

Once we have installed td-agent through yum we can now see the td-agent binary at /usr/sbin/td-agent:

``` 
$ which td-agent
/usr/sbin/td-agent
```

/opt/td-agent is where the embedded ruby + gems for td-agent is located at.

The default configuration file for td-agent is located at:

```
/etc/td-agent/td-agent.conf
```

You should update this configuration file and run td-agent as a service.

If you wish to only run td-agent against a test configuration file you can also run:

```
td-agent -c fluentd.conf
```

where fluentd.conf is the name of the configuration file you wish to supply via the -c flag to td-agent.

Once td-agent has been installed on an Artifactory or Xray node you will also need to install the relevant plugin if you are using Splunk or Datadog:

Splunk:
```
td-agent-gem install fluent-plugin-splunk-enterprise
```

Datadog:
``` 
td-agent-gem install fluent-plugin-datadog
```

For Prometheus or Elastic the required plugins are already installed along with td-agent so no additional plugins are necessary.


## Fluentd Config
At this point td-agent is installed however we need to download the configuration template file from the Jfrog log analytics github repo.

Inside this repo we will find a fluentd folder which has the configuration files we will need for Artifactory & Xray depending upon version.

See below links for a direct download by version:

[Artifactory 7.x+](https://github.com/jfrog/log-analytics/blob/master/fluentd/fluent.conf.rt)
[Xray 3.x+](https://github.com/jfrog/log-analytics/blob/master/fluentd/fluent.conf.xray)
[Artifactory 6.x](https://github.com/jfrog/log-analytics/blob/master/fluentd/fluent.conf.rt6)

Once we have the template downloaded we will need to update the fluent config file with the Splunk HTTP Event Collector (HEC) parameters from our Splunk instance.

## Splunk

Fluentd setup must be completed prior to Splunk.

To use the integration an administrator of Splunk will need to install the Jfrog Logs Application into Splunk.

This can be done through Splunkbase or manually by uploading the splunk/jfrog-logs.spl file into the "Install App From File" option in "Manage Apps".

Once the application has been installed either through Splunkbase or via manual file the next step will be to configure the HEC.

Our integration uses the [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) to send data to Splunk.

Users will need to configure the HEC to accept data (enabled) and also create a new token.

This will then need to be placed into the corresponding tags in the fluent configuration file in both locations where you see "HEC_TOKEN"

Users will also need to specify the HEC_HOST, HEC_PORT and if ssl is enabled the ca_file to be used.

``` 
<match jfrog.rt.router.request>
  @type splunk_hec
  host HEC_HOST
  port HEC_PORT
  token HEC_TOKEN
  format json
  # buffered output parameter
  flush_interval 10s
  # time format
  time_key time
  time_format %Y-%m-%dT%H:%M:%S.%LZ
  # ssl parameter
  use_ssl true
  ca_file /path/to/ca.pem
</match>
<match jfrog.**>
  @type splunk_hec
  host HEC_HOST
  port HEC_PORT
  token HEC_TOKEN
  format json
  # buffered output parameter
  flush_interval 10s
  # time format
  time_key timestamp
  time_format %Y-%m-%dT%H:%M:%S.%LZ
  # ssl parameter
  use_ssl true
  ca_file /path/to/ca.pem
</match>

```

### Demo

To run this integration for Splunk users can create a Splunk instance with the correct ports open in Kubernetes by applying the yaml file:

``` 
kubectl apply -f splunk/splunk.yaml
```

This will create a new Splunk instance you can use for a demo to send your Jfrog logs over to.

Once they have a Splunk up for demo purposes they will need to configure the HEC and then update fluent config files with the relevant parameters for HEC_HOST, HEC_PORT, & HEC_TOKEN.

At that point you will be ready to run fluentd see below section on steps how.

# Running Fluentd

Now that we have the new configuration file in place we can start the td-agent as a service on our system:

```
$ systemctl start td-agent
```

Alternatively we can run td-agent against the configuration file directly:

```
$ td-agent -c td-agent.conf
```

This will start the fluentd logging agent which will tail the JPD logs and send them all over to Splunk.

## Tools
* [Fluentd](https://www.fluentd.org) - Fluentd
* [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) - Splunk HEC used to upload data into Splunk

## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Contact
* Github
