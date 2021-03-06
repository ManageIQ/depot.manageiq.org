source 'https://rubygems.org'

# Override the Bundler :github shortcut to use HTTPS instead of the git protocol
# Note: Version 2.x of Bundler should do this by default
# git_source(:github) do |repo_name|
#   repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
#   "https://github.com/#{repo_name}.git"
# end

gem 'rake'
gem "rack", "= 1.5.2"

gem 'rails', '~> 4.1.4'

gem 'omniauth'
gem 'omniauth-chef-oauth2'
gem 'omniauth-github'

gem 'pg'
gem 'redcarpet' # markdown parsing
# gem 'unicorn'
# gem 'unicorn-rails'
gem 'foreman'
gem 'pundit'
gem 'dotenv'
gem 'coveralls', :require => false
gem 'octokit', :git => "https://github.com/octokit/octokit.rb"
gem 'sidekiq'
gem "safe_yaml", :require => false

# Pin sprockets to ensure we get the latest security patches. Not pinning this
# meant that the gem that depended on sprockets was pulling in an old
# (vulnerable) version.
gem 'sprockets', '~> 2.11.3'

# Use the version on GitHub because the version published on RubyGems has
# compatibility problems with Sidekiq 3.0.
gem 'sidetiq', :git => "https://github.com/tobiassvn/sidetiq", :ref => '4f7d7da'

gem 'premailer-rails', :group => [:development, :production]
gem 'nokogiri'
gem 'jbuilder'
gem 'pg_search'
gem 'paperclip'

# Pin virtus to a version before the handling of nil in collection coercion was
# fixed.
gem 'virtus', '1.0.2', :require => false

gem 'kaminari'
gem 'validate_url'
gem 'chef', :require => false
gem 'mixlib-authentication'
gem 'aws-sdk'
gem 'newrelic_rpm'
gem 'semverse'
gem 'sitemap_generator'
gem 'redis-rails'
gem 'yajl-ruby'
gem 'utf8-cleaner'
gem 'rinku', :require => 'rails_rinku'
gem 'html_truncator'
gem 'rollout'
gem 'statsd-ruby'
gem 'sentry-raven', '~> 0.8.0', :require => false
gem 'sass-rails',   '~> 4.0.4'
gem 'compass-rails'
gem 'uglifier',     '~> 2.2'

gem "capistrano", "~> 3.4.0"
gem "sinatra", :require => false

gem "airbrake"

group :doc do
  gem 'yard', :require => false
end

group :development do
  gem "capistrano-rbenv"
  gem "capistrano-rails"
  gem "capistrano3-unicorn"
  gem "capistrano-sidekiq"
  gem 'license_finder'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'factory_girl'
  gem 'poltergeist'

  # To prevent the validates_uniqueness matcher from raising a chef version
  # constraint error this pins shoulda-matchers at a commit where setting
  # default values for scopes was reverted
  gem 'shoulda-matchers', :git => "https://github.com/thoughtbot/shoulda-matchers", :ref => '380d18f0621c66a79445ebc6dcc0048fcc969911'

  gem 'database_cleaner'
  gem 'vcr', :require => false
  gem 'webmock', :require => false
end

group :development, :test do
  gem 'rubocop', '>= 0.23.0'
  gem 'mail_view'
  gem 'quiet_assets'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'byebug'
  gem 'launchy'

  # Pinned to be greater than or equal to 1.0.0.pre because the gems were prior
  # to 1.0.0 release when added
  gem 'and_feathers', '>= 1.0.0.pre', :require => false
  gem 'and_feathers-gzipped_tarball', '>= 1.0.0.pre', :require => false
end

group :production do
  gem "unicorn"
  gem "unicorn-rails"
end

