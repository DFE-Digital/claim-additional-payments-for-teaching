if ENV["LOGSTASH_HOST"].present?
  Rails.application.configure do
    SemanticLogger.add_appender(file_name: "log/#{Rails.env}.json", formatter: :json)
  end
end
