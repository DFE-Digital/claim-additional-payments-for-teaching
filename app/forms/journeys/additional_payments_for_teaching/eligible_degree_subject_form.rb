module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleDegreeSubjectForm < Form
      attribute :eligible_degree_subject, :boolean

      validates :eligible_degree_subject, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end
