module OrdnanceSurvey
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end

require_relative "ordnance_survey/api"
require_relative "ordnance_survey/api/v1"
require_relative "ordnance_survey/api/v1/search_places"
require_relative "ordnance_survey/client"
require_relative "ordnance_survey/client/response"
require_relative "ordnance_survey/client/response_error"
require_relative "ordnance_survey/configuration"
