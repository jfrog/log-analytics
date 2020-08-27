# Log Analytics with FluentD and Splunk

The following describes how to configure Fluentd and Splunk to gather logs from Artifactory and Xray.


| version | artifactory_version | xray_version | distribution_version      | splunk_version            |
|---------|---------------------|--------------|---------------------------|---------------------------|
| 0.3.0   | 7.7.3               | 3.8.0        | 2.4.2                     | 8.0.5 Build: a1a6394cc5ae |
| 0.2.0   | 7.7.3               | 3.8.0        | N/A                       | 8.0.5 Build: a1a6394cc5ae |
| 0.1.1   | 7.6.3               | 3.6.2        | N/A                       | 8.0.5 Build: a1a6394cc5ae |

## Splunk Config

Fluentd setup must be completed prior to Splunk. Please refer back to the main README for detailed instructions on general Fluentd setup.

To use the integration an administrator of Splunk will need to install the JFrog Logs Application into Splunk from Splunkbase.

The next step will be to configure the Splunk HEC.

Our integration uses the [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) to send data to Splunk.

Users will need to configure the HEC to accept data (enabled) and also create a new token. Save this token.

Users will also need to specify the HEC_HOST, HEC_PORT and if ssl is enabled the ca_file to be used.

``` 
<match jfrog.**>
  @type splunk_hec
  host HEC_HOST
  port HEC_PORT
  token HEC_TOKEN
  format json
  # buffered output parameter
  flush_interval 10s
  # ssl parameter
  use_ssl true
  ca_file /path/to/ca.pem
</match>
```

## Splunk Demo

To run this integration for Splunk users can create a Splunk instance with the correct ports open in Kubernetes by applying the yaml file:

``` 
kubectl apply -f splunk.yaml
```

This will create a new Splunk instance you can use for a demo to send your JFrog logs over to.

Once they have a Splunk up for demo purposes they will need to configure the HEC and then update fluent config files with the relevant parameters for HEC_HOST, HEC_PORT, & HEC_TOKEN.

They can now access Splunk to view the JFrog dashboard as new data comes in.

## Generating Data for Testing

To quickly generate data you can use the demo configuration fluentd files checked into the fluentd folder of this repo.

Point these are your Splunk instance to quickly load data into all the widgets of the dashboard.

## References

* [Fluentd](https://www.fluentd.org) - Fluentd Logging Aggregator/Agent
* [Splunk](https://www.splunk.com/) - Splunk Logging Platform
* [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) - Splunk HEC used to upload data into Splunk
