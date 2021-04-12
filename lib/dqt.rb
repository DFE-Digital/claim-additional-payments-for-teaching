module Dqt
  class << self
    attr_reader :configuration

    private

    attr_writer :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    class Client
      attr_accessor :host
    end

    def client
      @client ||= Client.new
    end
  end
end

require_relative "dqt/api"
require_relative "dqt/api/v1"
require_relative "dqt/api/v1/qualified_teaching_status"
require_relative "dqt/client"
require_relative "dqt/client/response"
require_relative "dqt/client/response_error"
