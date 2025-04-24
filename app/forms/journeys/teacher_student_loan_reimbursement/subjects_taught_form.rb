module Journeys
  module TeacherStudentLoanReimbursement
    class SubjectsTaughtForm < Form
      attribute :subjects_taught, default: []

      before_validation :clean_subjects_taught

      validates :subjects_taught,
        inclusion: {
          in: :possible_subjects,
          message: ->(form, _) { form.i18n_errors_path(:select_subject) }
        }

      validate :one_subject_must_be_selected

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(
          taught_eligible_subjects: taught_eligible_subjects,
          biology_taught: taught?("biology"),
          chemistry_taught: taught?("chemistry"),
          physics_taught: taught?("physics"),
          computing_taught: taught?("computing"),
          languages_taught: taught?("languages")
        )

        journey_session.save!
      end

      def claim_school_name
        @claim_school_name ||= answers.claim_school_name
      end

      def eligible_subjects
        Policies::StudentLoans::Eligibility::SUBJECT_ATTRIBUTES.map(&:to_s)
      end

      private

      def attributes_with_current_value
        if (params.dig(:claim, :subjects_taught) || []).include?("")
          {subjects_taught: params.dig(:claim, :subjects_taught)}
        else
          {subjects_taught: subjects_taught_from_session}
        end
      end

      def subjects_taught_from_session
        if journey_session.answers.taught_eligible_subjects == false
          return ["none_taught"]
        end

        eligible_subjects.select { |subject| journey_session.answers.public_send(subject) }
      end

      def possible_subjects
        (eligible_subjects + [:none_taught]).map(&:to_s)
      end

      def one_subject_must_be_selected
        return if (subjects_taught & possible_subjects).size > 0

        errors.add(:subjects_taught, i18n_errors_path(:select_subject))
      end

      def taught_eligible_subjects
        return false if subjects_taught.include?("none_taught")

        (subjects_taught & eligible_subjects).size > 0
      end

      def taught?(subject)
        subjects_taught.include?("#{subject}_taught")
      end

      def clean_subjects_taught
        subjects_taught.reject!(&:blank?)
      end
    end
  end
end
