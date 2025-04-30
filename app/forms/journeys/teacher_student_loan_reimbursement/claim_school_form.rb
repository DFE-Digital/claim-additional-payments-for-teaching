module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSchoolForm < Form
      MIN_LENGTH = 3

      attribute :provision_search, :string
      attribute :possible_claim_school_id, :string

      validates :provision_search,
        presence: {message: i18n_error_message(:blank)},
        length: {minimum: MIN_LENGTH, message: i18n_error_message(:min_length)},
        if: proc { |object| object.possible_claim_school_id.blank? || changed_query? }

      validate :validate_no_results

      def save
        return if invalid? || no_results?

        if possible_claim_school_id.present? && changed_possible_school?
          journey_session.answers.assign_attributes(
            claim_school_id: nil,
            possible_claim_school_id:
          )
          reset_dependent_answers
        end

        if changed_query?
          journey_session.answers.assign_attributes(
            claim_school_id: nil,
            possible_claim_school_id: nil,
            provision_search:
          )
          reset_dependent_answers
        end

        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(
          possible_claim_school_id: nil,
          provision_search: nil
        )

        journey_session.save!
      end

      def show_multiple_schools_content?
        !params.has_key?(:additional_school)
      end

      private

      def validate_no_results
        if possible_claim_school_id.blank? && no_results?
          errors.add :provision_search, message: "No results match that search term. Try again."
        end
      end

      def no_results?
        provision_search.present? && provision_search.size >= MIN_LENGTH && !has_results
      end

      def has_results
        @has_results ||= School.search(provision_search).count > 0
      end

      def changed_possible_school?
        possible_claim_school_id != journey_session.answers.claim_school_id
      end

      def changed_query?
        provision_search != journey_session.answers.provision_search
      end

      def reset_dependent_answers
        journey_session.answers.assign_attributes(
          taught_eligible_subjects: nil,
          biology_taught: nil,
          physics_taught: nil,
          chemistry_taught: nil,
          computing_taught: nil,
          languages_taught: nil,
          employment_status: nil,
          current_school_id: nil
        )
      end
    end
  end
end
