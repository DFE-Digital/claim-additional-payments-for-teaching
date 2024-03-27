# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

Rails.application.config.after_initialize do
  # Personal data in a claim
  Rails.application.config.filter_parameters |= Claim.filtered_params
  # Personal data in a session
  Rails.application.config.filter_parameters |= %i[user_info phone_number claim_postcode claim_address_line_1]
end
