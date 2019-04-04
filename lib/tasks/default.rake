task default: %i[rubocop brakeman:run spec] if Rails.env.test? || Rails.env.development?
