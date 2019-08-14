# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]

# Personally identifiable information
Rails.application.config.filter_parameters += [
  :address_line_1,
  :address_line_2,
  :address_line_3,
  :address_line_4,
  :postcode,
  :payroll_gender,
  :teacher_reference_number,
  :national_insurance_number,
  :email_address,
  :bank_sort_code,
  :bank_account_number,
  :SAMLResponse,
]
