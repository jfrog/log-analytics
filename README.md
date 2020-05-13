# JFrog Log Analytics
This project integrates Jfrog logs into various log analytic providers through the use of fluentd as a common logging agent.
The goal of this project is to provide Jfrog customers with robust log analytic solutions that they could use to monitor the Jfrog unified platform microservices.

## Table of Contents

   * [Fluentd Setup](#fluentd-setup)
   * [Splunk](#splunk)
     * [Demo](#demo)
   * [Tools](#tools)
   * [Contributing](#contributing)
   * [Versioning](#versioning)
   * [Contact](#contact)

## Fluentd Setup

Fluentd is required component to use the Jfrog log analytics integration.

For more details on how to install fluentd into your environment please visit:

[Fluentd installation guide](https://docs.fluentd.org/installation)

Fluentd has an agent called td-agent which will be required to be installed into each node you wish to monitor logs on.

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

## Splunk

Fluentd setup must be completed prior to Splunk.

Jfrog has created an integration for Splunk to consume our logs which will enable our customers who also use Splunk to utilize their existing Splunk infrastructure.

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

Deploy the Jfrog Logs application into this Splunk instance either through Splunkbase or manually by uploading the spl file to install the app.

Install fluentd's td-agent into your Artifactory & Xray, update the fluentd conf file, and enable it to run as a service.

Open the Jfrog Logs App Dashboard and confirm the dashboard is now rendering your log data.

## Tools
* [Fluentd](https://www.fluentd.org) - Fluentd
* [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) - Splunk HEC used to upload data into Splunk

## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Contact
* Github
