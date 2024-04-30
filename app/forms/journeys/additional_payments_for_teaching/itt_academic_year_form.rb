module Journeys
  module AdditionalPaymentsForTeaching
    class IttAcademicYearForm < Form
      attribute :itt_academic_year

      validates :itt_academic_year, presence: {message: ->(object, _) { object.i18n_errors_path(object.qualification) }}

      def save
        return false unless valid?
        return true unless itt_academic_year_changed?

        if claim.qualifications_details_check?
          update!(
            eligibility_attributes: {
              itt_academic_year: itt_academic_year
            }
          )
        else
          update!(
            eligibility_attributes: {
              itt_academic_year: itt_academic_year,
              eligible_itt_subject: nil
            }
          )
        end
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

      private

      def itt_academic_year_changed?
        claim.eligibility.itt_academic_year != itt_academic_year
      end
    end
  end
end
