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
        claim.eligibility.nqt_in_academic_year_after_itt && \
          available_subjects.many?
      end

      def chemistry_or_physics_available?
        available_subjects.include?("chemistry") || \
          available_subjects.include?("physics")
      end

      def save
        return false unless valid?
        return true unless eligible_itt_subject_changed?

        if claim.qualifications_details_check?
          update!(
            eligibility_attributes: {
              eligible_itt_subject: eligible_itt_subject
            }
          )
        else
          # FIXME RL: decide how to handle resetting `eligible_degree_subject`
          # and add test for it - only LUP eligibility has this field
          update!(
            eligibility_attributes: {
              eligible_itt_subject: eligible_itt_subject,
              teaching_subject_now: nil
            }
          )
        end

        true
      end

      private

      def eligible_itt_subject_changed?
        claim.eligibility.eligible_itt_subject != eligible_itt_subject
      end
    end
  end
end
