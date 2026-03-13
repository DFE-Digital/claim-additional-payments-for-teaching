module Journeys
  module EarlyYearsTeachers
    module Provider
      class CheckNurseryDetailsForm < Form
        attribute :nursery_details_confirmed, :boolean

        validates(
          :nursery_details_confirmed,
          inclusion: {
            in: [true, false],
            message: "Confirm if the nursery details are correct"
          }
        )

        def rows
          [
            {
              key: {text: "Nursery name"},
              value: {text: answers.nursery_name.humanize}
            },
            {
              key: {text: "Address"},
              value: {text: nursery_address}
            },
            {
              key: {text: "Ofsted URN"},
              value: {text: answers.ofsted_urn.humanize}
            },
            {
              key: {text: "Provider status"},
              value: {text: answers.provider_status.humanize}
            },
            {
              key: {text: "Type"},
              value: {text: answers.nursery_type.humanize}
            },
            {
              key: {text: "Subtype"},
              value: {text: answers.nursery_subtype.humanize}
            }
          ]
        end

        def radio_options
          [
            Option.new(id: true, name: "Yes"),
            Option.new(id: false, name: "No")
          ]
        end

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            nursery_details_confirmed: nursery_details_confirmed
          )
          journey_session.save!
        end

        private

        def nursery_address
          [
            answers.nursery_address_line_1,
            answers.nursery_address_city,
            answers.nursery_address_postcode
          ].join("<br>").html_safe
        end
      end
    end
  end
end
