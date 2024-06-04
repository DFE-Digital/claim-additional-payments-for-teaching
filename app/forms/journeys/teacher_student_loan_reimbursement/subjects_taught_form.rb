module Journeys
  module TeacherStudentLoanReimbursement
    class SubjectsTaughtForm < Form
      attr_accessor :subjects_taught

      attribute :taught_eligible_subjects, :boolean
      attribute :biology_taught, :boolean
      attribute :chemistry_taught, :boolean
      attribute :physics_taught, :boolean
      attribute :computing_taught, :boolean
      attribute :languages_taught, :boolean

      validate :one_subject_must_be_selected

      before_validation :determine_dependant_attributes

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          taught_eligible_subjects: taught_eligible_subjects,
          biology_taught: biology_taught,
          chemistry_taught: chemistry_taught,
          physics_taught: physics_taught,
          computing_taught: computing_taught,
          languages_taught: languages_taught
        )

        journey_session.save!
      end

      def claim_school_name
        @claim_school_name ||= answers.claim_school_name
      end

      def subject_attributes
        Policies::StudentLoans::Eligibility::SUBJECT_ATTRIBUTES
      end

      def subject_taught_selected?(subject)
        public_send(subject) == true if respond_to?(subject)
      end

      private

      def determine_dependant_attributes
        subject_attributes.each(&method(:update_subject_taught_attribute))
        assign_attributes(taught_eligible_subjects: selected_subjects.empty? ? nil : !no_subject_taught_selected?)
      end

      def update_subject_taught_attribute(subject)
        assign_attributes(subject => subject.to_s.in?(selected_subjects))
      end

      def no_subject_taught_selected?
        "none_taught".in?(selected_subjects)
      end

      def selected_subjects
        permitted_params.fetch(:subjects_taught, [])
      end

      def permitted_params
        @permitted_params ||= params.fetch(:claim, {}).permit(subjects_taught: [])
      end

      def any_subjects_taught_selected?
        subject_attributes.any?(&method(:subject_taught_selected?))
      end

      def not_taught_eligible_subjects?
        taught_eligible_subjects == false
      end

      def one_subject_must_be_selected
        return if not_taught_eligible_subjects? || any_subjects_taught_selected?

        errors.add(:subjects_taught, i18n_errors_path(:select_subject))
      end
    end
  end
end
