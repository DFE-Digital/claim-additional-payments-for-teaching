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

        # FIXME RL: Once this method writes to the journey session answers we
        # update the initializer in
        # AdditionalPaymentsForTeaching::QualificationDetailsForm
        # and update
        # QualificationForm#save to not reset eligible_itt_subject subject on
        # the claim, as it's no longer needed (still keep resetting it on the
        # answers) (and remove this comment!)
        claim.assign_attributes(
          eligibility_attributes: {eligible_itt_subject: eligible_itt_subject}
        )
        claim.reset_eligibility_dependent_answers(["eligible_itt_subject"])
        claim.save!

        true
      end
    end
  end
end
