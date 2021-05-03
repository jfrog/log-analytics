# fluent-plugin-jfrog-siem

[Fluentd](https://fluentd.org/) input plugin to download JFrog Xray SIEM violations and export them to Fluentd to process into various output plugins

## Building

To build / test locally use rake:

``` 
rake
```

To build install locally use bundler:

``` 
bundle install
```

This will install the gem shown below from source.


## Development

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-jfrog-siem"
```

And then execute:

```
$ bundle
```

### Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format input jfrog-siem
```

You can copy and paste generated documents here.

## Installation 

### RubyGems
```
$ gem install rest-client
```
```
$ gem install thread
```
```
$ gem install fluent-plugin-jfrog-siem
```

### Setup & configuration
Fluentd is the supported log collector for this integration. 
For Fluentd setup and information, read the JFrog log analytics repository's [README.](https://github.com/jfrog/log-analytics/blob/master/README.md)

#### Fluentd Output
Download fluentd conf for different log-vendors. For example
Splunk: 

Splunk setup can be found at [README.](https://github.com/jfrog/log-analytics-splunk/blob/master/README.md)
````text
wget https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master/siem/splunk_siem.conf
````
Elasticsearch: 

Elasticsearch Kibana setup can be found at [README.](https://github.com/jfrog/log-analytics-elastic/blob/master/README.md)
````text
wget https://raw.githubusercontent.com/jfrog/log-analytics-elastic/master/siem/elastic_siem.conf
````
Datadog: 

Datadog setup can be found at [README.](https://github.com/jfrog/log-analytics-datadog/blob/master/README.md)
````text
wget https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/siem/datadog_siem.conf
````

#### Configuration parameters
Integration is done by setting up Xray. Obtain JPD url and access token for API. Configure the source directive parameters specified below
* **tag** (string) (required): The value is the tag assigned to the generated events.
* **jpd_url** (string) (required): JPD url required to pull Xray SIEM violations
* **access_token** (string) (required): [Access token](https://www.jfrog.com/confluence/display/JFROG/Access+Tokens) to authenticate Xray
* **pos_file** (string) (required): Position file to record last SIEM violation pulled
* **batch_size** (integer) (optional): Batch size for processing violations
    * Default value: `25`
* **thread_count** (integer) (optional): Number of workers to process violation records in thread pool
    * Default value: `5`
* **wait_interval** (integer) (optional): Wait interval between pulling new events
    * Default value: `60`
    
## Copyright
* Copyright(c) 2020 - JFrog
* License
  * Apache License, Version 2.0
