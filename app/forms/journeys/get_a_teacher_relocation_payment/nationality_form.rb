module Journeys
  module GetATeacherRelocationPayment
    class NationalityForm < Form
      attribute :nationality, :string

      validates :nationality,
        inclusion: {
          in: NATIONALITIES,
          message: i18n_error_message(:inclusion)
        }

      def available_options
        NATIONALITIES
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(nationality: nationality)

        journey_session.save!
      end
    end
  end
end
