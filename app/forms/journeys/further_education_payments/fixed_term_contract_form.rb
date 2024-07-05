module Journeys
  module FurtherEducationPayments
    class FixedTermContractForm < Form
      attribute :fixed_term_full_year, :boolean

      validates :fixed_term_full_year,
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        [
          OpenStruct.new(
            id: true,
            name: t("options.true", current_academic_year: current_academic_year.to_s(:long))
          ),
          OpenStruct.new(
            id: false,
            name: t("options.false", current_academic_year: current_academic_year.to_s(:long))
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(fixed_term_full_year:)
        journey_session.save!
      end

      def current_academic_year
        @current_academic_year ||= AcademicYear.current
      end
    end
  end
end
