module Journeys
  module EarlyYearsTeachers
    module Provider
      class CheckYourEmailForm < Form
        attribute :check_your_email_clicked, :boolean

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            check_your_email_clicked: check_your_email_clicked,
            nursery_name: "Sunny Days Nursery",
            nursery_address_line_1: "123 Sunshine Lane",
            nursery_address_city: "London",
            nursery_address_postcode: "SW1A 1AA",
            ofsted_urn: "123456",
            provider_status: "active",
            nursery_type: "childcare_on_non_domestic_premises",
            nursery_subtype: "full_day_care"
          )
          journey_session.save!
        end
      end
    end
  end
end
