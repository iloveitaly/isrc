source 'https://rubygems.org'

# Specify your gem's dependencies in isrc.gemspec
gemspec

group :test do
  gem 'guard-rspec'
  gem 'pry'
  
  if RUBY_PLATFORM.downcase.include? "darwin"
   gem 'rb-fsevent'
   gem 'growl'
 end
end