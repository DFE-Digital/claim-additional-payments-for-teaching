task default: %i[shellcheck standard prettier brakeman:run spec] if Rails.env.test? || Rails.env.development?
