class ApplicationController < ActionController::Base
  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.has_key?("BASIC_AUTH_USERNAME") },
  )
end
