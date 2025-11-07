module Journeys
  class SessionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :service_access_code, :string

    def self.create!(params)
      new(params).tap(&:save!).journey_session
    end

    attr_reader :journey_session

    def initialize(params)
      super(permitted_params(params))
    end

    def save!
      @journey_session = journey::Session.create!(
        journey: journey.routing_name,
        answers: answers.reverse_merge(
          academic_year: journey.configuration.current_academic_year
        )
      )

      true
    end

    private

    def journey
      self.class.module_parent
    end

    def answers
      attributes.to_h
    end

    def permitted_params(params)
      params.fetch(:answers, {})
        .slice(*self.class.attribute_names)
        .permit(*self.class.attribute_names)
    end
  end
end
