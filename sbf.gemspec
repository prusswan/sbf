$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sbf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sbf"
  s.version     = Sbf::VERSION
  s.authors     = ["prusswan"]
  s.email       = ["prusswan@gmail.com"]
  s.homepage    = "https://github.com/prusswan/sbf"
  s.summary     = "Summary of Sbf."
  s.description = "Description of Sbf."
  s.license     = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.0.1"
  s.add_dependency "rails_admin"
  s.add_dependency "cancan"

  s.add_development_dependency "sqlite3"
end
