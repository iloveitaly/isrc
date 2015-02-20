source 'https://rubygems.org'
gemspec

gem 'mechanize', '2.7.0'

group :test do
  gem 'guard-rspec'
  gem 'pry'
  gem 'pry-nav'
  
  if RUBY_PLATFORM.downcase.include? "darwin"
   gem 'rb-fsevent'
   gem 'growl'
 end
end