module Journeys
  module FurtherEducationPayments
    class FurtherEducationTeachingStartYearForm < Form
      attribute :further_education_teaching_start_year, :string

      validates :further_education_teaching_start_year,
        presence: {message: i18n_error_message(:blank)}

      def radio_options
        years_before = -4

        array = (years_before..0).map do |delta|
          academic_year = AcademicYear.current + delta
          OpenStruct.new(
            id: academic_year.start_year.to_s,
            name: t("options.between_dates", start_year: academic_year.start_year, end_year: academic_year.end_year)
          )
        end

        academic_year = AcademicYear.current + years_before
        array << OpenStruct.new(
          id: "pre-#{academic_year.start_year}",
          name: t("options.before_date", year: academic_year.start_year)
        )

        array
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(further_education_teaching_start_year:)
        journey_session.save!
      end
    end
  end
end
