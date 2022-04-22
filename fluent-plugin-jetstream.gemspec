lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-jetstream"
  spec.version = "0.1.0"
  spec.authors = ["leegun2000"]
  spec.email   = ["leegun_2000@naver.com"]

  spec.summary       = %q{nats streaming plugin for fluentd, an event collector}
  spec.description   = %q{nats streaming plugin for fluentd, an event collector}
  spec.homepage      = "https://github.com/leegun2000/fluent-plugin-jetstream.git"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  # spec.files        = ["lib/fluent/plugin/in_jetstream.rb"]
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2.32"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "test-unit", "~> 3.3.7"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  spec.add_runtime_dependency "nats-pure", "~> 2.0.0"
end
