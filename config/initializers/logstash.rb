if ENV["LOGSTASH_HOST"].present?
  Rails.application.configure do
    tcp_logger = LogStashLogger.new(type: :tcp,
                                    host: ENV.fetch("LOGSTASH_HOST"),
                                    port: ENV.fetch("LOGSTASH_PORT"),
                                    ssl_enable: true)

    SemanticLogger.add_appender(logger: tcp_logger, level: :info, formatter: :json)
  end
end
