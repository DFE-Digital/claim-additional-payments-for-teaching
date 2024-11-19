module Journeys
  module AdditionalPaymentsForTeaching
    class IttAcademicYearForm < Form
      attribute :itt_academic_year

      validates :itt_academic_year, presence: {message: ->(object, _) { object.i18n_errors_path(object.qualification) }}

      def save
        return false unless valid?

        if reset_dependent_answers?
          journey_session.answers.assign_attributes(eligible_itt_subject: nil)
        end

        journey_session.answers.assign_attributes(
          itt_academic_year: itt_academic_year
        )

        journey_session.save!
      end

      def qualification
        answers.qualification
      end

      def qualification_is?(*symbols)
        symbols.any? qualification.to_sym
      end

      def selectable_itt_years_for_claim_year
        AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(
          journey.configuration.current_academic_year
        )
      end

      def itt_academic_year_changed?
        answers.itt_academic_year != itt_academic_year
      end

      def reset_dependent_answers?
        itt_academic_year_changed? && !answers.qualifications_details_check?
      end
    end
  end
end
