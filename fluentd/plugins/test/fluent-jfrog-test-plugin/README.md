# fluent-jfrog-test-plugin

[Fluentd](https://fluentd.org/) test plugin to verify JFrog Log Analytics integration

## Building

To build / test locally use rake:

````ruby
rake
````

To build install locally use bundler:

````ruby
bundle install
````

This will install the gem shown below from source.


## Installation

### RubyGems

````ruby
gem install fluent-jfrog-test-plugin
````

### Bundler

Add following line to your Gemfile:

````ruby
gem "fluent-jfrog-test-plugin"
````

And then execute:

````ruby
bundle
````

## Tests

To test the latest version of our regex against a log directory set the `JFROG_LOG_DIR` ENV.

Then run:

````ruby
bundle
````

Artifactory
````ruby
ruby test/plugin/jfrog_log_analytic_rt_test.rb 
````

Xray
````ruby
ruby test/plugin/jfrog_log_analytic_xray_test.rb
````

Distribution
````ruby
ruby test/plugin/jfrog_log_analytic_distribution_test.rb
````


To use this gem to test JFrog Artifactory 6.x set the `ARTIFACTORY_LOG_DIR` ENV.

Then run:

````ruby
bundle
````

````ruby
ruby lib/fluent/plugin/jfrog_log_analytic_rt6_test.rb
````

## Copyright

* Copyright(c) 2020 - JFrog
* License
  * Apache License, Version 2.0
