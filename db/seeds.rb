require "faker"
Faker::Config.locale = "en-GB"

require_relative "seeders/base"
require_relative "seeders/null"
require_relative "seeders/development"
require_relative "seeders/review"

seeder = if Rails.env.development?
  Seeders::Development.new
elsif Rails.env.test?
  Seeders::Null.new
else
  Seeders::Review.new
end

seeder.call
