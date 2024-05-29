module Journeys
  module AdditionalPaymentsForTeaching
    class IttAcademicYearForm < Form
      attribute :itt_academic_year

      validates :itt_academic_year, presence: {message: ->(object, _) { object.i18n_errors_path(object.qualification) }}

      def save
        return false unless valid?

        # FIXME RL: Once this method writes to the journey session answers we
        # update the initializer in
        # AdditionalPaymentsForTeaching::QualificationDetailsForm
        claim.assign_attributes(eligibility_attributes: {itt_academic_year:})
        claim.reset_eligibility_dependent_answers(["itt_academic_year"])
        claim.save!
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
