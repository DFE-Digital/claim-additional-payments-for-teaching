module Journeys
  class Session < ApplicationRecord
    self.abstract_class = true

    has_one :claim,
      dependent: :nullify,
      inverse_of: :journeys_session,
      foreign_key: :journeys_session_id

    validates :journey,
      presence: true,
      inclusion: {in: Journeys.all_routing_names}

    def submitted?
      claim.present?
    end

    # This method and the associated `answers_hash` are temporary methods while
    # we're working with both a current claim and journey session.
    # When setting default values in a form object we need to know if the
    # answer was stored on the journey session or whether we should check the
    # current claim. Values for answers may be `nil`, so we need to check if
    # the answer key exists in the database.
    # Once all forms has been migrated to use the journey session, this method
    # can be removed.
    def answered?(attribute_name)
      answers_hash.with_indifferent_access.has_key?(attribute_name)
    end

    private

    def answers_hash
      # Support using build in specs
      if answers_before_type_cast.is_a?(Hash)
        answers_before_type_cast
      else
        JSON.parse(answers_before_type_cast)
      end
    end
  end
end
