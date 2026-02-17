module Journeys
  module EarlyYearsTeachers
    module Provider
      class OrganisationEmailAddressForm < Form
        attribute :organisation_email_address, :string

        validates(
          :organisation_email_address,
          presence: {message: "Enter your organisation email address"}
        )

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            organisation_email_address: organisation_email_address
          )
          journey_session.save!
        end
      end
    end
  end
end
