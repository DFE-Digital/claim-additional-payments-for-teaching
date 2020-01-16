require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

require_relative "../lib/verify"
require_relative "../lib/student_loan"
require_relative "../lib/dfe_sign_in"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DfeTeachersPaymentService
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.active_job.queue_adapter = :delayed_job

    # Set a css_compressor so sassc-rails does not overwrite the compressor
    config.assets.css_compressor = nil

    # Set the application time zone to UK. Times are still stored as UTC in the database
    config.time_zone = "London"

    # Make sure the `form_with` helper generates local forms, instead of defaulting
    # to remote and unobtrusive XHR forms
    config.action_view.form_with_generates_remote_forms = false

    config.guidance_url = "https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details"

    if ENV["LOGSTASH_HOST"].present?
      tcp_logger = LogStashLogger.new(type: :tcp,
                                      host: ENV.fetch("LOGSTASH_HOST"),
                                      port: ENV.fetch("LOGSTASH_PORT"),
                                      ssl_enable: true)

      SemanticLogger.add_appender(logger: tcp_logger, level: :info, formatter: :json)
    end
  end
end
