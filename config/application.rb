require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

require_relative "../lib/student_loan"
require_relative "../lib/csv_importer"
require_relative "../lib/dfe_sign_in"
require_relative "../lib/hmrc"
require_relative "../lib/ordnance_survey"
require_relative "../lib/dqt"
require_relative "../lib/notify_sms_message"

require "govuk/components"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DfeTeachersPaymentService
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

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

    # Additional information which is passed in the logs for each request
    # See https://rocketjob.github.io/semantic_logger/rails.html#named-tags
    config.log_tags = {
      request_id: :request_id
    }

    config.active_record.yaml_column_permitted_classes = [BigDecimal, Date, Symbol]

    config.email_regexp = /\A[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+\z/
  end
end
