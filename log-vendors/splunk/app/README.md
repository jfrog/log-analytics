# JFrog Platform Log Analytics Splunk App Development

## App Directory Structure
A Splunk App has a specific directory structure for packaging. Most of your development will be in [jfrog-logs/default/data/ui](jfrog-logs/default/data/ui) using [Simple XML](https://docs.splunk.com/Documentation/Splunk/8.0.5/Viz/PanelreferenceforSimplifiedXML) to layout your dashboard UI. CSS and Javascript in [jfrog-logs/appserver/static](jfrog-logs/appserver/static) can provide additional styling and functionality.
![App Directory Structure](https://dev.splunk.com/enterprise/static/app-overview-directorystructure-b397da01a76c1122a7c3c389f0c8ebeb.png)

### Local Development
#### Installing Splunk Enterprise Locally
It may be easier to install Splunk Enterprise locally for quicker development. You can install Splunk Enterprise from [here](https://www.splunk.com/en_us/download/splunk-enterprise.html).

With Splunk Enterprise running, you can develop from the apps directory at _$SPLUNK_HOME/etc/apps/jfrog-logs_. Edit the UI xml files here and restart the server to see the changes. Use the Splunk CLI (_$SPLUNK_HOME/bin/splunk_) to restart the server.

```
$ splunk [start | stop | restart]
```

Occasionally, you may need to clear your index to start from scratch:

```
$ splunk stop
$ splunk clean eventdata -index <index name>
$ splunk start
```

#### Installing Fluentd Locally
You can install FluentD locally and send demo data. This works particularly well for dashboard and chart enhancements. You can send demo data without having a full Artifactory and Xray deployment. You can modify your demo data quickly to achieve the type of visualizations needed.

##### Install FluentD (OSX)
```
$ gem install fluentd --no-doc
```

##### Install Splunk FluentD Plugin (OSX)
```
$ gem install fluent-plugin-splunk-hec
```
### Demo Data
Demo data that populates all dashboard and charts can be used to verify your development. You can use the config file [fluentd-demo.conf](../fluentd-demo.conf) as an example. Add and modify _dummy_ data as needed. 

```
$ fluentd -c fluentd-demo.conf
```

### Static File Changes (CSS, JS)
CSS and JS file changes require cache updates to be seen. Clear your browser cache. You also need to clear the Splunk webserver cache. Do this from http://<splunk_server>/_bump.

### Update app.conf
Before packaging the app, update the [app.conf](jfrog-logs/default/app.conf). Make sure  update the version.

### Package the App
To package the app, use the Splunk CLI. 

```
$ cd jfrog-logs
$ splunk package app jfrog-logs
```

### Install the App
Install the app in your Splunk instance through the _Apps > Manage Apps > Install app from file_.

### Create the HEC Data Input to Receive Data
You may need to create a new HTTP Event Collector data input. You can do this at _Settings > Data Inputs > HTTP Event Collector_. Use the JFrog app as the context. Then use the token in the FluentD configs:

```
<match jfrog.**>
  @type splunk_hec
    hec_host HEC_HOST
    hec_port HEC_PORT
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

### Removing the App
To completely remove the app use the Splunk CLI:

```
$ splunk remove app jfrog-logs
```
Note: This will also remove the HEC Event Collector.

### Use Splunk AppInspect to Pre-Validate the App
Before submitting the app to Splunkbase for validation, use the [Splunk AppInspect API](https://dev.splunk.com/enterprise/docs/developapps/testvalidate/appinspect/splunkappinspectapi/runappinspectrequestsapi) to pre-validate and resolve issues.

### Submitting to Splunkbase
When testing and validation is complete, follow these [instructions](https://dev.splunk.com/enterprise/docs/releaseapps/splunkbase/submitcontentui) for submitting the app to Splunkbase.
## References
* [Develop Splunk Apps](https://dev.splunk.com/enterprise/docs/developapps)
* [Simple XML Reference for Apps](https://docs.splunk.com/Documentation/Splunk/8.0.5/Viz/PanelreferenceforSimplifiedXML)