module Journeys
  module GetATeacherRelocationPayment
    class ContractDetailsForm < Form
      attribute :one_year, :boolean

      validates :one_year,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def available_options
        [true, false]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(one_year: one_year)

        journey_session.save!
      end
    end
  end
end
