# frozen_string_literal: true

# see https://github.com/reidmorrison/rails_semantic_logger/issues/249
# see https://github.com/reidmorrison/rails_semantic_logger/pull/276

LAST_TESTED_VERSION = "4.18.0"

require "rails_semantic_logger/version"

unless RailsSemanticLogger::VERSION == LAST_TESTED_VERSION
  raise "rails_semantic_logger is version #{RailsSemanticLogger::VERSION} but the monkey patch was last tested on " \
        "#{LAST_TESTED_VERSION} - manually check if it can find the sql_runtime module."
end

module RailsSemanticLogger
  module ActiveRecord
    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        if ::ActiveRecord::RuntimeRegistry.respond_to?(:stats)
          ::ActiveRecord::RuntimeRegistry.stats.sql_runtime = value
        else
          ::ActiveRecord::RuntimeRegistry.sql_runtime = value
        end
      end

      def self.runtime
        if ::ActiveRecord::RuntimeRegistry.respond_to?(:stats)
          ::ActiveRecord::RuntimeRegistry.stats.sql_runtime ||= 0
        else
          ::ActiveRecord::RuntimeRegistry.sql_runtime ||= 0
        end
      end
    end
  end
end
