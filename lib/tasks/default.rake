task default: %i[standard prettier brakeman:run spec] if Rails.env.test? || Rails.env.development?
