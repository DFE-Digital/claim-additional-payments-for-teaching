module Journeys
  module GetATeacherRelocationPayment
    class EmploymentDetailsForm < Form
      attribute :school_headteacher_name, :string
      attribute :school_name, :string
      attribute :school_address_line_1, :string
      attribute :school_address_line_2, :string
      attribute :school_city, :string
      attribute :school_postcode, :string

      validates :school_headteacher_name,
        presence: {
          message: i18n_error_message(:school_headteacher_name)
        }

      validates :school_name,
        presence: {
          message: i18n_error_message(:school_name)
        }

      validates :school_address_line_1,
        presence: {
          message: i18n_error_message(:school_address_line_1)
        }

      validates :school_city,
        presence: {
          message: i18n_error_message(:school_city)
        }

      validates :school_postcode,
        presence: {
          message: i18n_error_message(:school_postcode)
        }

      validate :school_postcode_is_valid, if: -> { school_postcode.present? }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          school_headteacher_name: school_headteacher_name,
          school_name: school_name,
          school_address_line_1: school_address_line_1,
          school_address_line_2: school_address_line_2,
          school_city: school_city,
          school_postcode: school_postcode
        )

        journey_session.save!
      end

      private

      def school_postcode_is_valid
        unless UKPostcode.parse(school_postcode).full_valid?
          errors.add(:school_postcode, i18n_errors_path(:school_postcode))
        end
      end
    end
  end
end
