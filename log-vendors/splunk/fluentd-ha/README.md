# Splunk Fluentd HA Configuration

This guide will help you setup our log analytics solution utilizing fluentd in an HA configuration.

For more information on general fluentd ha configuration please visit: [Fluentd HA](https://docs.fluentd.org/deployment/high-availability)

## Fluentd HA Installation

To setup Fluentd in an HA setup you will need to install Fluentd on 2 or more machines.

You can follow the root or non-root based installation guides on our main README to install fluentd into each node.

Once you have installed fluentd on at least two machines that will act as the aggregator server ha setup you can then proceed to configuration.

## Splunk Config

To configure Fluentd in an HA setup you will need to configure the Artifactory or Xray node as before but instead of sending the logs to the log vendor it must ship the logs via forwarders to the fluentd aggregator setup.

First we must configure the Fluentd on the aggregator primary and backup server.

We will need to download the fluent.conf.aggregator configuration into each machine and deploy it with the correct Splunk configurations like below:

``` 
<match jfrog.**>
  @type splunk_hec
  host 10.10.0.1
  port 8088
  token my_api_token
  format json
  # buffered output parameter
  flush_interval 10s
  # ssl parameter
  use_ssl true
  ca_file /path/to/ca.pem
</match>
```

We need to change the host to the correct host address and update the token to the value of the HEC token we created in Splunk. If we are using SSL we will also need to supply the ca_file of the Splunk HEC instance.

Repeat this process on both the primary and backup aggregator server. Take note of the host/IP and port as we will need to supply these to each Artifactory/Xray instance in the next step.

You will need to update the log forwarder section on each Artifactory or Xray node to replace the host and port of your primary and backup aggregator server as shown below:

```
# Log Forwarding
<match jfrog.**>
  @type forward
  # primary host
  <server>
    host 192.168.0.1
    port 24224
  </server>
  # use secondary host
  <server>
    host 192.168.0.2
    port 24224
    standby
  </server>
  # use longer flush_interval to reduce CPU usage.
  # note that this is a trade-off against latency.
  <buffer>
    flush_interval 30s
  </buffer>
</match>
```

In this example we would replace the 192.168.0.1 with the correct address of the primary fluentd aggregator server node. Also verify the port is correct based upon the configurations we gave to the aggregator fluentd conf.

At this point we can know start the process on the Artifactory or Xray node to ship the logs to our aggregator primary or backup that will send the logs to Splunk.