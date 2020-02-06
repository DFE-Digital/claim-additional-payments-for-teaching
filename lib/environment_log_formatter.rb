class EnvironmentLogFormatter < SemanticLogger::Formatters::Json
  def call(log, logger)
    log = log.dup
    log.named_tags = log.named_tags.dup.tap do |named_tags|
      named_tags[:environment] = ENV.fetch("ENVIRONMENT_NAME")
    end

    super(log, logger)
  end
end
