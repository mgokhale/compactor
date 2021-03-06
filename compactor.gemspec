# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "compactor/version"

Gem::Specification.new do |gem|
  gem.name        = "compactor"
  gem.version     = Compactor::VERSION
  gem.authors     = ["Julio Santos"]
  gem.email       = ["julio@morgane.com"]
  gem.homepage    = ""
  gem.summary     = "Scrape Amazon Seller Central"
  gem.description = "Scrape Amazon Seller Central"

  gem.rubyforge_project = "compactor"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "mechanize", "2.4"

  if RUBY_PLATFORM == "java"
    gem.add_runtime_dependency "jruby-openssl", '0.7.3'
    gem.add_runtime_dependency "nokogiri", ">= 1.5.0", "< 1.5.3"
  end

  gem.add_development_dependency "rake"
  gem.add_development_dependency "mocha", "0.12.1"
  gem.add_development_dependency "vcr", "~>2.0.0"
  gem.add_development_dependency "fakeweb"
  gem.add_development_dependency "rcov", "0.9.11"
end
