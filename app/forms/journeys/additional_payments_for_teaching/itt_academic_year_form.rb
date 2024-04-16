module Journeys
  module AdditionalPaymentsForTeaching
    class IttAcademicYearForm < Form
      attribute :itt_academic_year

      validates :itt_academic_year, presence: {message: ->(object, _) { object.i18n_errors_path(object.qualification) }}

      def initialize(claim:, journey:, params:)
        super

        self.itt_academic_year = permitted_params.fetch(:itt_academic_year, claim.eligibility.itt_academic_year)
      end

      def save
        return false unless valid?

        update!({eligibility_attributes: {itt_academic_year:}})
      end

      def qualification
        @claim.eligibility.qualification
      end

      def qualification_is?(*symbols)
        symbols.any? qualification.to_sym
      end

      def selectable_itt_years_for_claim_year
        JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year journey.configuration.current_academic_year
      end
    end
  end
end
