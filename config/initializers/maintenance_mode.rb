Rails.application.config.maintenance_mode = ENV["MAINTENANCE_MODE"].present?
Rails.application.config.maintenance_mode_availability_message = ENV["MAINTENANCE_MODE_AVAILABILITY_MESSAGE"]
