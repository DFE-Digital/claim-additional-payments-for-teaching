module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class GenderForm < Form
        VALID_GENDERS = %w[female male non_binary other prefer_not_to_say].freeze

        attribute :payroll_gender, :string
        attribute :payroll_gender_other, :string

        validates :payroll_gender,
          inclusion: {
            in: VALID_GENDERS,
            message: i18n_error_message(:inclusion)
          }

        validates :payroll_gender_other,
          presence: {message: i18n_error_message(:other_required)},
          if: -> { payroll_gender == "other" }

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            payroll_gender: payroll_gender,
            payroll_gender_other: payroll_gender == "other" ? payroll_gender_other : nil
          )
          journey_session.save!
        end

        def radio_options
          [
            OpenStruct.new(id: "female", name: "Female"),
            OpenStruct.new(id: "male", name: "Male"),
            OpenStruct.new(id: "non_binary", name: "Non-binary"),
            OpenStruct.new(id: "other", name: "Other"),
            OpenStruct.new(id: "prefer_not_to_say", name: "Prefer not to say")
          ]
        end
      end
    end
  end
end
