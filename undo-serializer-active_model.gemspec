# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'undo/serializer/active_model'

Gem::Specification.new do |spec|
  spec.name          = "undo-serializer-active_model"
  spec.version       = Undo::Serializer::ActiveModel::VERSION
  spec.authors       = ["Alexander Paramonov"]
  spec.email         = ["alexander.n.paramonov@gmail.com"]
  spec.summary       = %q{Pass though serializer for Undo gem}
  spec.description   = %q{Pass though serializer for Undo gem. It do nothing and returns whatever passed to it.}
  spec.homepage      = "http://github.com/AlexParamonov/undo-serializer-active_model"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "active_model_serializers", "~> 0.8"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0.beta1"
end
