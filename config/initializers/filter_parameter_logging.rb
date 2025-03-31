# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# Personal data in a claim
Rails.application.config.after_initialize do
  Rails.application.config.filter_parameters += Journeys::JOURNEYS.flat_map(&:pii_attributes).uniq
  Rails.application.config.filter_parameters += SignInOrContinueForm::TeacherIdUserInfoForm::DFE_IDENTITY_ATTRIBUTES
end

# Personal data in a report
Rails.application.config.filter_parameters += [:csv]
