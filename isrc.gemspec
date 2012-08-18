# -*- encoding: utf-8 -*-
require File.expand_path('../lib/isrc/version', __FILE__)

Gem::Specification.new do |g|
  g.authors       = ["Michael Bianco"]
  g.email         = ["info@cliffsidedev.com"]
  g.description   = "Pull ISRC codes from PPLK UK's database"
  # g.summary       = %q{TODO: Write a gem summary}
  g.homepage      = "http://github.com/iloveitaly/isrc"

  g.files         = `git ls-files`.split($\)
  g.executables   = g.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  g.test_files    = g.files.grep(%r{^(test|spec|features)/})
  g.name          = "isrc"
  g.require_paths = ["lib"]
  g.version       = ISRC::VERSION

  g.add_dependency 'httparty'
  g.add_dependency 'nokogiri'
  g.add_dependency 'mechanize'

  g.add_development_dependency 'rspec'
  g.add_development_dependency 'guard'
end
