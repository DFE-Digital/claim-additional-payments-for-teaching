module Journeys
  module TargetedRetentionIncentivePayments
    class IttYearForm < Form
      attribute :itt_academic_year, :string

      validates :itt_academic_year, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: ->(form, _) do
          form.t([:errors, :inclusion, form.answers.qualification])
        end
      }

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

      def radio_options
        Policies::TargetedRetentionIncentivePayments
          .selectable_itt_years_for_claim_year(
            journey.configuration.current_academic_year
          )
          .map { Option.new(id: it.to_s, name: it.to_s(:long)) }
          .push(none_of_the_above)
      end

      # We implicitly rely on AcademicYear type casting "none_of_the_above"
      # into a "none" AcademicYear.
      def none_of_the_above
        Option.new(
          id: NONE_OF_THE_ABOVE_ACADEMIC_YEAR,
          name: "None of the above"
        )
      end

      private

      def itt_academic_year_changed?
        answers.itt_academic_year != itt_academic_year
      end

      def reset_dependent_answers?
        itt_academic_year_changed? && !answers.qualifications_details_check?
      end
    end
  end
end
