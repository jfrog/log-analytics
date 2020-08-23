# fluent-jfrog-test-plugin

[Fluentd](https://fluentd.org/) test plugin to verify JFrog Log Analytics integration

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
$ gem install fluent-jfrog-test-plugin
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-jfrog-test-plugin"
```

And then execute:

```
$ bundle
```

## Usage

To use this gem to test JFrog Unified Platform set the `JFROG_LOG_DIR` ENV.

Then run:

`bundle`

`ruby lib/fluent/plugin/jfrog_log_analytic_platform_test.rb`


To use this gem to test JFrog Artifactory 6.x set the `ARTIFACTORY_LOG_DIR` ENV.

Then run:

`bundle`

`ruby lib/fluent/plugin/jfrog_log_analytic_rt6_test.rb`

## Copyright

* Copyright(c) 2020 - JFrog
* License
  * Apache License, Version 2.0
