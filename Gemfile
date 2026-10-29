# frozen_string_literal: true

source 'https://rubygems.org'

group :development do
  # Gem management
  gem 'juwelier'
  # juwelier 2.4.9 calls Git::Repository#lib, which git 6 removed
  gem 'git', '< 6'
end

group :test, :development do
  gem 'byebug', require: 'byebug'
end

group :test do
  # Test
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'simplecov-cobertura'
  gem 'webmock', '~> 3.34'
  gem 'webrick'
end
