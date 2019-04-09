task default: %i[standard brakeman:run spec] if Rails.env.test? || Rails.env.development?
