module Journeys
  module EarlyYearsTeachers
    module Provider
      class UpdateNurseryDetailsForm < Form
        attribute :nursery_name, :string
        attribute :nursery_address_line_1, :string
        attribute :nursery_address_city, :string
        attribute :nursery_address_postcode, :string
        attribute :ofsted_urn, :string
        attribute :provider_status, :string
        attribute :nursery_type, :string
        attribute :nursery_subtype, :string

        attribute :nursery_details_updated, :boolean

        validates(
          :nursery_name,
          presence: {message: "Enter the nursery name"}
        )

        validates(
          :nursery_address_line_1,
          presence: {message: "Enter the nursery address"}
        )

        validates(
          :nursery_address_city,
          presence: {message: "Enter the nursery address"}
        )

        validates(
          :nursery_address_postcode,
          presence: {message: "Enter the nursery postcode"}
        )

        validates(
          :ofsted_urn,
          presence: {message: "Enter the Ofsted URN"}
        )

        validates(
          :provider_status,
          inclusion: {
            in: ->(form) { form.provider_status_options.map(&:id) },
            message: "Select the provider status"
          }
        )

        validates(
          :nursery_type,
          inclusion: {
            in: ->(form) { form.nursery_type_options.map(&:id) },
            message: "Select the nursery type"
          }
        )

        validates(
          :nursery_subtype,
          inclusion: {
            in: ->(form) { form.nursery_subtype_options.map(&:id) },
            message: "Select the nursery subtype"
          }
        )

        validates :nursery_details_updated, presence: true

        def provider_status_options
          [
            Option.new(id: "active", name: "Active"),
            Option.new(id: "inactive", name: "Inactive"),
            Option.new(id: "suspended", name: "Suspended"),
            Option.new(id: "cancelled", name: "Cancelled"),
            Option.new(id: "resigned", name: "Resigned"),
            Option.new(id: "refused", name: "Refused")
          ]
        end

        def nursery_type_options
          [
            Option.new(
              id: "childcare_on_non_domestic_premises",
              name: "Childcare on non-domestic premises"
            ),
            Option.new(
              id: "childcare_on_domestic_premises",
              name: "Childcare on domestic premises"
            ),
            Option.new(
              id: "childminder",
              name: "Childminder"
            ),
            Option.new(
              id: "childcare_register_only",
              name: "Childcare register only"
            ),
            Option.new(
              id: "school_based_provision",
              name: "School-based provision"
            )
          ]
        end

        def nursery_subtype_options
          [
            Option.new(id: "full_day_care", name: "Full day care"),
            Option.new(id: "sessional_day_care", name: "Sessional day care")
          ]
        end

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            nursery_name: nursery_name,
            nursery_address_line_1: nursery_address_line_1,
            nursery_address_city: nursery_address_city,
            nursery_address_postcode: nursery_address_postcode,
            ofsted_urn: ofsted_urn,
            provider_status: provider_status,
            nursery_type: nursery_type,
            nursery_subtype: nursery_subtype,
            nursery_details_updated: nursery_details_updated
          )
          journey_session.save!
        end
      end
    end
  end
end
