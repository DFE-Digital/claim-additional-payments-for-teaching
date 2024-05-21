module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleDegreeSubjectForm < Form
      attribute :eligible_degree_subject, :boolean

      validates :eligible_degree_subject, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      # FIXME RL: Once this method writes to the journey session answers we
      # update the initializer in
      # AdditionalPaymentsForTeaching::QualificationDetailsForm
      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end
