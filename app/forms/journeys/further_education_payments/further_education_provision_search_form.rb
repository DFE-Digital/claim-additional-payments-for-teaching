module Journeys
  module FurtherEducationPayments
    class FurtherEducationProvisionSearchForm < Form
      MIN_LENGTH = 3

      attribute :provision_search, :string
      attribute :possible_school_id, :string

      validates :provision_search,
        presence: {message: i18n_error_message(:blank)},
        length: {minimum: MIN_LENGTH, message: i18n_error_message(:min_length)},
        unless: proc { |object| object.possible_school_id.present? }

      def no_results?
        provision_search.present? && provision_search.size >= MIN_LENGTH && !has_results
      end

      def save
        return if invalid? || no_results?

        reset_dependent_answers if changed_answer?

        if possible_school_id.present?
          journey_session.answers.assign_attributes(
            possible_school_id:
          )
        else
          journey_session.answers.assign_attributes(
            provision_search:
          )
        end

        journey_session.save!

        true
      end

      private

      def has_results
        School.search(provision_search).count > 0
      end

      def changed_answer?
        if possible_school_id.present?
          possible_school_id != journey_session.answers.school_id
        else
          true
        end
      end

      def reset_dependent_answers
        journey_session.answers.assign_attributes(
          school_id: nil
        )
      end
    end
  end
end
