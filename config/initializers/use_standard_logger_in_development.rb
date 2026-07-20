# In development we use the standard Rails logger instead of rails_semantic_logger.
#
# The rails_semantic_logger engine deletes Rails' own :initialize_logger
# initializer and forces `Rails.logger = SemanticLogger[Rails]` during boot, so
# we can't simply assign config.logger in config/environments/development.rb.
# Files in config/initializers/ are loaded *after* the engine's
# :initialize_logger initializer, so this is the earliest deterministic point at
# which we can swap the logger back.
#
# Combined with `config.rails_semantic_logger.semantic = false` (set in
# development.rb), this gives the plain, readable Rails log output.
if Rails.env.development?
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = Rails.application.config.log_formatter
  Rails.logger = Rails.application.config.logger = ActiveSupport::TaggedLogging.new(logger)
end
