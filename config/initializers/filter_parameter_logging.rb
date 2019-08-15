# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# Personally identifiable information in a claim
Rails.application.config.filter_parameters += Claim.filtered_params

# Sensitive parameter in Verify response
Rails.application.config.filter_parameters += [:SAMLResponse]
