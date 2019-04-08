task default: %i[brakeman:run spec] if Rails.env.test? || Rails.env.development?
