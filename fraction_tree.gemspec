require "date"

Gem::Specification.new do |spec|
  spec.name        = "fraction-tree"
  spec.version     = "2.1.1"
  spec.summary     = "Fraction tree"
  spec.description = "A collection of Stern-Brocot based models and methods"
  spec.authors     = ["Jose Hales-Garcia"]
  spec.email       = "jose@halesgarcia.com"
  spec.homepage    = "https://jolohaga.github.io/fraction-tree/"
  spec.metadata = {
    "source_code_uri" => "https://github.com/jolohaga/fraction-tree"
  }
  spec.license     = "MIT"
  spec.date        = Date.today.to_s
  spec.files       = Dir.glob("lib/**/*")
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")
  spec.required_rubygems_version = Gem::Requirement.new(">= 3.1")
  spec.rubygems_version = "3.5.23"
  spec.add_runtime_dependency "matrix", ["~> 0.4"]
  spec.add_runtime_dependency "forwardable", ["~> 1.3"]
  spec.add_runtime_dependency "continued_fractions", ["~> 2.1"]
  spec.add_development_dependency "rspec", ["~> 3"]
  spec.add_development_dependency "byebug", ["~> 11.1"]
  spec.add_development_dependency "yard", ["~> 0.9"]
  spec.add_development_dependency "rspec-benchmark", ["~> 0.6"]
end
