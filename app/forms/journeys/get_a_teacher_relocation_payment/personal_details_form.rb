module Journeys
  module GetATeacherRelocationPayment
    class PersonalDetailsForm < PersonalDetailsForm
      with_options if: -> { date_of_birth && date_of_birth.is_a?(Date) } do
        validates :date_of_birth,
          comparison: {
            less_than_or_equal_to: ->(_) { 21.years.ago },
            message: PersonalDetailsForm.i18n_error_message(:below_min_age)
          }

        validates :date_of_birth,
          comparison: {
            greater_than: ->(_) { 80.years.ago },
            message: PersonalDetailsForm.i18n_error_message(:over_max_age)
          }
      end
    end
  end
end
