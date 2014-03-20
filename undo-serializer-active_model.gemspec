# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "undo-serializer-active_model"
  spec.version       = IO.read("VERSION")
  spec.authors       = ["Alexander Paramonov"]
  spec.email         = ["alexander.n.paramonov@gmail.com"]
  spec.summary       = %q{ActiveModel serializer for Undo gem. Does not require anything from Rails so is friendly to use with POROs.}
  spec.description   = %q{ActiveModel serializer for Undo gem. Does not require anything from Rails so is friendly to use with POROs.}
  spec.homepage      = "http://github.com/AlexParamonov/undo-serializer-active_model"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'undo', '~> 0.1.0'
  spec.add_development_dependency 'bundler', '~> 1.0'
end
