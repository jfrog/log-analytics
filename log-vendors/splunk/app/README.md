# JFrog Splunk App Development

## App Directory Structure
A Splunk App has a specific directory structure for packaging. Most of your development will be in [jfrog-logs/default/data/ui](jfrog-logs/default/data/ui) using [Simple XML](https://docs.splunk.com/Documentation/Splunk/8.0.5/Viz/PanelreferenceforSimplifiedXML) to layout your dashboard UI. CSS and Javascript in [jfrog-logs/appserver/static](jfrog-logs/appserver/static) can provide additional styling and functionality.
![App Directory Structure](https://dev.splunk.com/enterprise/static/app-overview-directorystructure-b397da01a76c1122a7c3c389f0c8ebeb.png)

### Local Splunk Enterprise Development for Faster Development
It may be easier to install Splunk Enterprise locally easier to development. You can install Splunk Enterprise from [here](https://www.splunk.com/en_us/download/splunk-enterprise.html).

With Splunk Enterprise running, you can develop from the apps directory at _$SPLUNK_HOME/etc/apps/jfrog-logs_. Edit the UI xml files here and restart the server to see the changes. Use the Splunk CLI (_$SPLUNK_HOME/bin/splunk_) to restart the server.

```
$ splunk [start | stop | restart]
```

### Demo Data
Demo data that populates all dashboard and charts can be used to verify your development. Use the config file [fluentd-demo.conf](../fluentd-demo.conf). 

```
$ fluentd -c demo.conf
```

### Static File Changes (CSS, JS)
CSS and JS file changes require cache updates to be seen. Clear your browser cache. You also need to clear the Splunk webserver cache. Do this from http://<splunk_server>/_bump.

### Update app.conf
Before packaging the app, update the [app.conf](jfrog-logs/default/app.conf). Make sure  update the version.

### Package the App
To package the app, tar it. 

```
$ tar -cvf jfrog-logs-<VERSION>.spl jfrog-logs/
```

### Install the App
Install the app in your Splunk instance through the Apps > Manage Apps > Install app from file

### Create the HEC Data Input to Receive Data
You may need to create a new HTTP Event Collector data input. You can do this at Settings > Data Inputs > HTTP Event Collector. Use the JFrog app as the context. Then use the token in the FluentD configs:

```
<match jfrog.**>
  @type splunk_hec
    host HEC_HOST
    port HEC_PORT
    token HEC_TOKEN <-- replace HEC_TOKEN
    format json
    sourcetype_key log_source
    use_fluentd_time false
    # buffered output parameter
    flush_interval 10s
    # ssl parameter
    #use_ssl true
    #ca_file /path/to/ca.pem
</match>
#END SPLUNK OUTPUT
```

### Removing the App
To completely remove the app use the Splunk CLI:

```
splunk remove app jfrog-logs
```

## References
* [Develop Splunk Apps](https://dev.splunk.com/enterprise/docs/developapps)
* [Simple XML Reference for Apps](https://docs.splunk.com/Documentation/Splunk/8.0.5/Viz/PanelreferenceforSimplifiedXML)