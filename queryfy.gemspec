# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'queryfy/version'

Gem::Specification.new do |spec|
	spec.name          = "queryfy"
	spec.version       = Queryfy::VERSION
	spec.authors       = ["Bonemind"]
	spec.email         = ["subhime@gmail.com"]

	spec.summary       = %q{Query activerecord models based on query strings}
	spec.description   = %q{Query activerecord models based on sql-like syntax with arbitratily deeply nested conditions}
	spec.homepage      = "https://github.com/Bonemind/Queryfy"
	spec.license       = "MIT"

	# Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
	# delete this section to allow pushing this gem to any host.
	if spec.respond_to?(:metadata)
		spec.metadata['allowed_push_host'] = "https://rubygems.org"
	else
		raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
	end

	spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
	spec.bindir        = "exe"
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]

	spec.add_runtime_dependency 'filter_lexer', '~>0.2', '>= 0.2.1'
	spec.add_development_dependency "bundler", "~> 1.10"
	spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency "sqlite3"
end
