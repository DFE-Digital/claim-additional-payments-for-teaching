module Hmrc
  module Employments
    extend Hmrc::ClientConfiguration
  end
end

require_relative "employments/response_error"
require_relative "employments/client"
require_relative "employments/configuration"
require_relative "employments/matching_request"
require_relative "employments/employment_history_request"
