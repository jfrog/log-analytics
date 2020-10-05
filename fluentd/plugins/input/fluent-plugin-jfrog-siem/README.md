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

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-jfrog-siem"
```

And then execute:

```
$ bundle
```

## Configuration

You can generate configuration template:

```
$ fluent-plugin-config-format input jfrog-siem
```

You can copy and paste generated documents here.

###Setup & configuration parameters

Xray setup is required. Obtain JPD url and access token for API

* **tag** (string) (required): The value is the tag assigned to the generated events.
* **jpd_url** (string) (required): JPD url required to pull Xray SIEM violations
* **access_token** (string) (required): [Access token](https://www.jfrog.com/confluence/display/JFROG/Access+Tokens) to authenticate Xray
* **pos_file** (string) (required): Position file to record last SIEM violation pulled
* **batch_size** (integer) (optional): Batch size for processing violations
    * Default value: `25`.
* **thread_count** (integer) (optional): Number of workers to process violation records in thread pool
    * Default value: `5`.
* **wait_interval** (integer) (optional): Wait interval between pulling new events
    * Default value: `60`.
    
## Copyright

* Copyright(c) 2020 - JFrog
* License
  * Apache License, Version 2.0
