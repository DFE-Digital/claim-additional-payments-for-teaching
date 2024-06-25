module Journeys
  module GetATeacherRelocationPayment
    class VisaForm < Form
      VISA_OPTIONS = [
        "Afghan Relocations and Assistance Policy",
        "Afghan citizens resettlement scheme",
        "British National (Overseas) visa",
        "Family visa",
        "High Potential Individual visa",
        "India Young Professionals Scheme visa",
        "Skilled worker visa",
        "UK Ancestry visa",
        "Ukraine Family Scheme visa",
        "Ukraine Sponsorship Scheme",
        "Youth Mobility Scheme",
        "Other"
      ].freeze

      attribute :visa_type, :string

      validates :visa_type,
        inclusion: {
          in: VISA_OPTIONS,
          message: i18n_error_message(:inclusion)
        }

      def available_options
        VISA_OPTIONS
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(visa_type: visa_type)

        journey_session.save!
      end
    end
  end
end
