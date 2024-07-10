module Journeys
  module GetATeacherRelocationPayment
    class HeadteacherDetailsForm < Form
      attribute :school_headteacher_name, :string

      validates :school_headteacher_name,
        presence: {
          message: i18n_error_message(:school_headteacher_name)
        }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          school_headteacher_name: school_headteacher_name
        )

        journey_session.save!
      end
    end
  end
end
