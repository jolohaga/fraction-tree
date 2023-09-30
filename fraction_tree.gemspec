require "date"

Gem::Specification.new do |spec|
  spec.name        = "fraction-tree"
  spec.version     = "0.1.0"
  spec.summary     = "Fraction tree"
  spec.description = "A collection of Stern-Brocot based models and methods"
  spec.authors     = ["Jose Hales-Garcia"]
  spec.email       = "jose@halesgarcia.com"
  spec.files       = Dir.glob("lib/**/*")
  spec.add_runtime_dependency "continued_fractions", ["~> 1.8"]
  spec.add_development_dependency "rspec", ["~> 3.2"]
  spec.add_development_dependency "byebug", ["~> 11.1"]
  spec.add_development_dependency "yard", ["~> 0.9"]
  spec.homepage    = "https://rubygems.org/gems/fraction-tree"
  spec.license     = "MIT"
  spec.date        = Date.today.to_s
end
