# frozen_string_literal: true

# see https://github.com/reidmorrison/rails_semantic_logger/issues/249

LAST_TESTED_VERSION = "4.17.0"

require "rails_semantic_logger/version"

unless RailsSemanticLogger::VERSION == LAST_TESTED_VERSION
  raise "rails_semantic_logger is version #{RailsSemanticLogger::VERSION} but the monkey patch was last tested on #{LAST_TESTED_VERSION} - manually check if it supports Rails 8 now and this can be removed, or that this still works as intended"
end

module LogSubscriberMonkeyPatch
  def self.included(base)
    base.alias_method(:bind_values, :bind_values_v6_1)
    base.alias_method(:render_bind, :render_bind_v6_1)
    base.alias_method(:type_casted_binds, :type_casted_binds_v5_1_5)
  end
end

RailsSemanticLogger::ActiveRecord::LogSubscriber.include(LogSubscriberMonkeyPatch)
