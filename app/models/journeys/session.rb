module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journey_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    def submitted?
      claim.present?
    end

    # This method and the associated `before_save` callback are temporary
    # methods while we're working with both a current claim and journey
    # session.
    # When setting default values in a form object we need to know if the
    # answer was stored on the journey session or whether we should check the
    # current claim. Values for answers may be `nil`, so we need to explicitly
    # check that the question was answered.
    # Once all forms has been migrated to use the journey session, this method,
    # the before_save call back and the SessionAnswer#answered attribute can be
    # removed.
    def answered?(attribute_name)
      answers.answered.include?(attribute_name.to_s)
    end

    before_save do
      answers.answered += answers.changes.keys.map(&:to_s)
    end
  end
end
