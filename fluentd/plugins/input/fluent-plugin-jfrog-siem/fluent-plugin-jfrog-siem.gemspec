lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-jfrog-siem"
  spec.version = "0.1.9"
  spec.authors = ["John Peterson", "Mahitha Byreddy"]
  spec.email   = ["johnp@jfrog.com", "mahithab@jfrog.com"]

  spec.summary       = %q{JFrog SIEM fluent input plugin will send the SIEM events from JFrog Xray to Fluentd}
  spec.description   = %q{JFrog SIEM fluent input plugin will send the SIEM events from JFrog Xray to Fluentd which can then be delivered to whatever output plugin specified}
  spec.homepage      = "https://github.com/jfrog/log-analytics"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "rest-client", "~> 2.0"
  spec.add_development_dependency "thread", "~> 0.2.2"
  spec.add_runtime_dependency "thread", "~> 0.2.2"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
