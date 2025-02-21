module Journeys
  module TargetedRetentionIncentivePayments
    class IttAcademicYearForm < Form
      attribute :itt_academic_year

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
        AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(
          journey.configuration.current_academic_year
        )
        .map { Option.new(id: it.to_s, name: it.to_s(:long)) }
        .push(
          Option.new(id: "itt_academic_year_none", name: "None of the above")
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

