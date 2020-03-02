if ENV["LOGSTASH_HOST"].present?
  LogStashLogger.configure do |logstash_config|
    logstash_config.customize_event do |event|
      event["named_tags"]["environment"] = ENV.fetch("ENVIRONMENT_NAME")
    end
  end

  logstash_logger = LogStashLogger.new(type: :multi_delegator,
                                       outputs: [
                                         {type: :stdout}, # good practice for Docker containers
                                         {
                                           type: :tcp,
                                           host: ENV.fetch("LOGSTASH_HOST"),
                                           port: ENV.fetch("LOGSTASH_PORT"),
                                           ssl_enable: true
                                         }
                                       ])

  SemanticLogger.add_appender(logger: logstash_logger, level: :info, formatter: :json)
end
