# frozen_string_literal: true

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rake'
require 'juwelier'
require_relative 'lib/version'

# Repository files that are not shipped in the gem.
GEM_FILES_EXCLUDE = %w[
  .bumpversion.toml
  .github/**/*
  .circleci/**/*
  catalog-info.yaml
  .auto-approve.yaml
  .gitar/**/*
  .releaserc.mjs
  renovate.json5
  .gitlab-ci.yml
  license_checker.sh
  spec/**/*
].freeze

Juwelier::Tasks.new do |gem|
  gem.name = 'deepl-rb'
  gem.homepage = 'https://github.com/DeepLcom/deepl-rb'
  gem.license = 'MIT'
  gem.summary = 'Official Ruby library for the DeepL language translation API.'
  gem.description =
    'Official Ruby library for the DeepL language translation API (v2). ' \
    'For more information, check this: https://www.deepl.com/docs/api-reference.html'
  gem.version = DeepL::VERSION
  gem.required_ruby_version = '>= 3.0'

  gem.email = 'open-source@deepl.com'
  gem.authors = ['DeepL SE']
  gem.metadata = {
    'bug_tracker_uri' => 'https://github.com/DeepLcom/deepl-rb/issues',
    'changelog_uri' => 'https://github.com/DeepLcom/deepl-rb/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/DeepLcom/deepl-rb/blob/main/README.md',
    'homepage_uri' => 'https://github.com/DeepLcom/deepl-rb'
  }
  gem.files.exclude(*GEM_FILES_EXCLUDE)
end

Juwelier::RubygemsDotOrgTasks.new

# Tests
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new

namespace :spec do
  desc 'Run the offline specs: no network, no key.'
  RSpec::Core::RakeTask.new(:offline) { |task| task.pattern = 'spec/offline/**/*_spec.rb' }

  desc 'Run the real-API specs: needs DEEPL_AUTH_KEY, sends real requests.'
  RSpec::Core::RakeTask.new(:real_api) { |task| task.pattern = 'spec/real_api/**/*_spec.rb' }
end

desc 'Run the offline specs.'
task spec: 'spec:offline'

desc 'Run the offline specs and rubocop.'
task :test do
  Rake::Task['spec'].invoke
  Rake::Task['rubocop'].invoke
end

task default: :test
