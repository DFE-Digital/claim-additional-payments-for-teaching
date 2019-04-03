task default: %i[rubocop spec] if Rails.env.test? || Rails.env.development?
