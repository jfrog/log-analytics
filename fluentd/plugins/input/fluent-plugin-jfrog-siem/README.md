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

## Copyright

* Copyright(c) 2020 - JFrog
* License
  * Apache License, Version 2.0
