source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "6.0.3.4"
# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 5.1"
# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.11"
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

# Database based asynchronous priority queue system
gem "delayed_job_active_record"
gem "delayed_cron_job"

# Geckoboard for stats
gem "geckoboard-ruby"

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

# Allow delayed_job to spawn multiple processes
gem "daemons"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  gem "rspec-rails"
  gem "capybara"
  gem "brakeman", require: false
  gem "standard"
  gem "bullet"
  gem "webmock"
  gem "shoulda-matchers"
  gem "factory_bot_rails"
  gem "dotenv-rails"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"

  gem "listen", ">= 3.0.5", "< 3.5"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"

  gem "foreman"
  gem "webdrivers"
end

group :test do
  gem "selenium-webdriver"
  gem "launchy"
  gem "climate_control"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
