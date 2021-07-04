# frozen_string_literal: true

require_relative "lib/db2_query/version"

Gem::Specification.new do |spec|
  spec.name        = "db2_query"
  spec.version     = Db2Query::VERSION
  spec.authors     = ["yohanes_l"]
  spec.email       = ["yohanes.lumentut@gmail.com"]
  spec.homepage    = "https://github.com/yohaneslumentut"
  spec.summary     = "Db2 ODBC adapter"
  spec.description = "A Rails Db2 ODBC adapter"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yohaneslumentut/db2_query"
  spec.metadata["changelog_uri"] = "https://github.com/yohaneslumentut/db2_query"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rails", "~> 6.1.3", ">= 6.1.3.2"

  spec.add_dependency "connection_pool", "~> 2.2", ">= 2.2.5"
  spec.add_dependency "ruby-odbc"
end
