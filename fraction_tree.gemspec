require "date"

Gem::Specification.new do |spec|
  spec.name        = "fraction-tree"
  spec.version     = "0.1.2"
  spec.summary     = "Fraction tree"
  spec.description = "A collection of Stern-Brocot based models and methods"
  spec.authors     = ["Jose Hales-Garcia"]
  spec.email       = "jose@halesgarcia.com"
  spec.homepage    = "https://jolohaga.github.io/fraction-tree/"
  spec.metadata = {
    "source_code_uri" => "https://github.com/jolohaga/fraction-tree"
  }
  spec.files       = Dir.glob("lib/**/*")
  spec.required_ruby_version = Gem::Requirement.new(">= 2.2.2")
  spec.add_runtime_dependency "continued_fractions", ["~> 1.8"]
  spec.add_development_dependency "rspec", ["~> 3.2"]
  spec.add_development_dependency "byebug", ["~> 11.1"]
  spec.add_development_dependency "yard", ["~> 0.9"]
  spec.license     = "MIT"
  spec.date        = Date.today.to_s
end
