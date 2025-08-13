module Journeys
  module FurtherEducationPayments
    class FixedTermContractForm < Form
      attribute :fixed_term_full_year, :boolean

      validates :fixed_term_full_year,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: i18n_error_message(:inclusion)
        }

      def radio_options
        [
          Option.new(
            id: true,
            name: t("options.true", current_academic_year: current_academic_year)
          ),
          Option.new(
            id: false,
            name: t("options.false", current_academic_year: current_academic_year)
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(fixed_term_full_year:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(fixed_term_full_year: nil)
        journey_session.save!
      end

      def current_academic_year
        @current_academic_year ||= AcademicYear.current.to_s(:long)
      end
    end
  end
end
