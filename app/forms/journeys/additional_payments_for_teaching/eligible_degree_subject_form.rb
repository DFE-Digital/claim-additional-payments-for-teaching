module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleDegreeSubjectForm < Form
      attribute :eligible_degree_subject, :boolean

      validates :eligible_degree_subject, inclusion: {
        in: [true, false],
        message: ->(object, _) { object.i18n_errors_path("select_eligible_degree_subject") }
      }

      def initialize(claim:, journey:, params:)
        super

        self.eligible_degree_subject = permitted_params.fetch(
          :eligible_degree_subject,
          lupp_claim.eligibility.eligible_degree_subject
        )
      end

      def save
        return false unless valid?

        update!({eligibility_attributes: {eligible_degree_subject:}})
      end
    end
  end
end
