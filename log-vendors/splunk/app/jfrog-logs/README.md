# JFrog Platform Log Analytics Splunk App

## Getting Started
Install the app in your Splunk instance. Then restart your Splunk instance by going to _Server Controls > Restart_.

## Create the HEC Data Input to Receive Data
You may need to create a new HTTP Event Collector data input. You can do this at _Settings > Data Inputs > HTTP Event Collector_. Use the JFrog app as the context. Then use the token as the HEC_TOKEN as described below in the FluentD configuration.

## Install FluentD
FluentD is used to send log events to Splunk. This [repo](https://github.com/jfrog/log-analytics) contains instructions on various installations options for Fluentd as a logging agent. The FluentD configuration must specify the HEC_HOST, HEC_PORT and HEC_TOKEN.
```
<match jfrog.**>
  @type splunk_hec
    hec_host HEC_HOST <-- splunk host
    hec_port HEC_PORT <-- splunk HEC port
    hec_token HEC_TOKEN <-- replace HEC_TOKEN
    format json
    sourcetype_key log_source
    use_fluentd_time false
    # buffered output parameter
    # flush_interval 10s
    # ssl parameter
    #use_ssl true
    #ca_file /path/to/ca.pem
</match>
#END SPLUNK OUTPUT
```

## Additional Setup

For complete instructions on setup of the integration between JFrog Artifactory & Xray to Splunk visit our Github [repo](https://github.com/jfrog/log-analytics)

This [repo](https://github.com/jfrog/log-analytics) will contain instructions on various installations options of fluentd as a logging agent to collect logs to be sent to Splunk.