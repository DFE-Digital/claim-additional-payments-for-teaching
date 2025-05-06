source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.3"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 8.0"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 6.6"
# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0"
# Use Terser as compressor for ES6 JavaScript assets
gem "terser"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.13"
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Generate human-readable reference numbers
gem "nanoid"

# Use Rollbar
gem "rollbar"

# Use OmniAuth with OpenIDConnect
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"

# ActionMailer support for GOV.UK Notify
gem "mail-notify"

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

# Allows generation of a JWT token to interact with the DfE Login API
gem "jwt"

# Send app telemetry to Azure Application Insights
gem "application_insights", git: "https://github.com/microsoft/ApplicationInsights-Ruby.git", ref: "5db6b4ad65262d23f26b678143a4a1fd7939e5c2"

# Semantic Logger provides more useful application log entries
gem "rails_semantic_logger"

# Improved memory usage in downloading large files vs Net/HTTP
gem "httpclient"

# Gov form builder to structure claims
gem "govuk_design_system_formbuilder", "~> 5.9.0"
gem "govuk-components", "~> 5.9.0"

gem "govuk_publishing_components"

# See https://github.com/typhoeus/ethon/issues/185
gem "ethon", "~> 0.16.0"
gem "typhoeus", "~> 1.4.1"

# ROTP requried for Early Career Payments one-time password
gem "rotp"

gem "uk_postcode"

gem "faraday_middleware"

# required for prod due to Azure DEV/TEST all running as 'production'
gem "faker", "~> 3.5", require: false
# speed up bulk imports
gem "activerecord-copy", require: false

gem "pagy"

gem "ostruct"

gem "solid_queue", "~> 1.1"
gem "mission_control-jobs"

gem "pry"
gem "rspec-rails"
gem "turbo_tests"
gem "capybara"
gem "brakeman", require: false
gem "standard"
gem "bullet"
gem "webmock"
gem "shoulda-matchers"
gem "factory_bot_rails"
gem "dotenv-rails"

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"

  gem "listen", ">= 3.0.5", "< 3.10"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1.0"

  gem "foreman"
  # Provides a detailed speed badge for every HTML page to aid performance optimisation.
  gem "rack-mini-profiler"
end

group :test do
  gem "rspec-retry"
  gem "launchy"
  gem "rack_session_access"
  gem "simplecov", require: false
  # Return null object for active record connection rather than raising error
  gem "activerecord-nulldb-adapter"
  gem "cuprite"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "dfe-analytics", github: "DFE-Digital/dfe-analytics", tag: "v1.15.5"
