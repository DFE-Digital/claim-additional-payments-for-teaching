module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleIttSubjectForm < Form
      include Claims::IttSubjectHelper

      attribute :eligible_itt_subject, :string

      validates :eligible_itt_subject, inclusion: {in: :available_options, message: i18n_error_message(:inclusion)}

      def available_subjects
        @available_subjects ||= subject_symbols(claim).map(&:to_s)
      end

      def available_options
        available_subjects + ["none_of_the_above"]
      end

      def show_hint_text?
        claim.eligibility.nqt_in_academic_year_after_itt &&
          available_subjects.many?
      end

      def chemistry_or_physics_available?
        available_subjects.include?("chemistry") ||
          available_subjects.include?("physics")
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          eligible_itt_subject:,
        )

        journey_session.save!
      end
    end
  end
end
