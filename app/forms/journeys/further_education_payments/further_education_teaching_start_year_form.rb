module Journeys
  module FurtherEducationPayments
    class FurtherEducationTeachingStartYearForm < Form
      attribute :further_education_teaching_start_year, :string

      validates :further_education_teaching_start_year,
        presence: {
          message: ->(object, data) { i18n_error_message(:blank, before_year: object.before_year).call(object, data) }
        }

      YEARS_BEFORE = -4

      def radio_options
        array = (YEARS_BEFORE..0).map do |delta|
          academic_year = AcademicYear.current + delta
          OpenStruct.new(
            id: academic_year.start_year.to_s,
            name: t("options.between_dates", start_year: academic_year.start_year, end_year: academic_year.end_year)
          )
        end

        array << OpenStruct.new(
          id: "pre-#{before_year}",
          name: t("options.before_date", year: before_year)
        )

        array
      end

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(further_education_teaching_start_year:)
        journey_session.save!
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(further_education_teaching_start_year: nil)
        journey_session.save!
      end

      def before_year
        academic_year = AcademicYear.current + YEARS_BEFORE
        academic_year.start_year
      end
    end
  end
end
