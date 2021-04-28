lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-jfrog-buildinfo"
  spec.version = "0.1.0"
  spec.authors = ["MahithaB"]
  spec.email   = ["60710901+MahithaB@users.noreply.github.com"]

  spec.summary       = %q{JFrog Fluentd BuildInfo plugin will send build information from Artifactory}
  spec.description   = %q{JFrog Fluentd BuildInfo plugin will send build information from Artifactory which can then be delivered to whatever output plugin specified}
  spec.homepage      = "https://github.com/jfrog/log-analytics"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "rest-client", "~> 2.0"
  spec.add_development_dependency "thread", "~> 0.2.2"
  spec.add_runtime_dependency "thread", "~> 0.2.2"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
