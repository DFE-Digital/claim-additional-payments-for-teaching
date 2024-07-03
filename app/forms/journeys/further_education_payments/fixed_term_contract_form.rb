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
            name: "Yes, it covers the full #{current_academic_year.to_s(:long)} academic year"
          ),
          OpenStruct.new(
            id: false,
            name: "No, it does not cover the full #{current_academic_year.to_s(:long)} academic year"
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
