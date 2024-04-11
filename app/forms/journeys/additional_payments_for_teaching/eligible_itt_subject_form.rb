module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleIttSubjectForm < Form
      include Claims::IttSubjectHelper

      attribute :eligible_itt_subject, :string

      validates :eligible_itt_subject,
        inclusion: {
          in: :available_options,
          message: ->(form, _) { form.i18n_errors_path(:inclusion) }
        }

      def initialize(journey:, claim:, params:)
        super

        self.eligible_itt_subject = permitted_params.fetch(
          :eligible_itt_subject,
          claim.eligibility.eligible_itt_subject
        )
      end

      def available_options
        subject_symbols(claim).map(&:to_s) + ["none_of_the_above"]
      end

      def save
        return false unless valid?

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
