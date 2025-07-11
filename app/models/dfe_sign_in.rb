module DfeSignIn
  class ExternalServerError < StandardError; end

  class << self
    attr_accessor :configurations

    def configuration_for_client_id(client_id)
      config = configurations.find { |c| c.client_id == client_id }

      if config.nil?
        raise "No DfE Sign In config found for client_id: #{client_id}"
      end

      config
    end

    def configure
      self.configurations ||= []

      new_config = Configuration.new
      yield(new_config)

      self.configurations << new_config
    end
  end

  class Configuration
    attr_accessor :client_id,
      :secret,
      :base_url
  end
end
