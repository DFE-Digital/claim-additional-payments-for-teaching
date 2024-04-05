module Journeys
  module AdditionalPaymentsForTeaching
    class PoorPerformanceForm < Form
      attribute :subject_to_formal_performance_action, :boolean
      attribute :subject_to_disciplinary_action, :boolean

      validates :subject_to_formal_performance_action, inclusion: {in: [true, false], message: ->(object, _) { object.i18n_errors_path("select_subject_to_formal_performance_action") }}
      validates :subject_to_disciplinary_action, inclusion: {in: [true, false], message: ->(object, _) { object.i18n_errors_path("select_subject_to_disciplinary_action") }}

      def initialize(claim:, journey:, params:)
        super

        self.subject_to_formal_performance_action = permitted_params.fetch(:subject_to_formal_performance_action, claim.eligibility.subject_to_formal_performance_action)
        self.subject_to_disciplinary_action = permitted_params.fetch(:subject_to_disciplinary_action, claim.eligibility.subject_to_disciplinary_action)
      end

      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end