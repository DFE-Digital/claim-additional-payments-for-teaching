module OrdnanceSurvey
  class Api
    class V1
      class SearchPlaces
        def initialize(client:)
          self.client = client
        end

        def index(params:)
          mapped_params = {
            postcode: params[:postcode].delete(" ")
          }

          response = client.get(path: "/search/places/v1/postcode", params: mapped_params)

          return nil unless response && response[:results].present?

          response[:results].map do |result|
            {
              address: titleize_address(full_address: result[:DPA][:ADDRESS]),
              address_line_1: address_line_1(sub_building_name: result[:DPA][:SUB_BUILDING_NAME], building_name: result[:DPA][:BUILDING_NAME], building_number: result[:DPA][:BUILDING_NUMBER]),
              address_line_2: result[:DPA][:THOROUGHFARE_NAME],
              address_line_3: result[:DPA][:POST_TOWN],
              postcode: result[:DPA][:POSTCODE]
            }
          end
        end

        def show(params:)
          mapped_params = {
            query: [params[:address_line_1], params[:postcode].delete(" ")].join(", "),
            maxresults: 1,
            minmatch: 0.4
          }

          response = client.get(path: "/search/places/v1/find", params: mapped_params)

          return nil unless response && response[:results].present?

          response[:results].map do |result|
            {
              address: titleize_address(full_address: result[:DPA][:ADDRESS]),
              address_line_1: address_line_1(sub_building_name: result[:DPA][:SUB_BUILDING_NAME], building_name: result[:DPA][:BUILDING_NAME], building_number: result[:DPA][:BUILDING_NUMBER]),
              address_line_2: result[:DPA][:THOROUGHFARE_NAME],
              address_line_3: result[:DPA][:POST_TOWN],
              postcode: result[:DPA][:POSTCODE]
            }
          end
        end

        private

        attr_accessor :client

        def titleize_address(full_address:)
          address = full_address.split(", ")
          address_line_1 = /\A\d.*\z/.match?(address.first) ? address.first : address.first.titleize

          [
            address_line_1,
            address.values_at(1..(address.size - 2)).join(", ").titleize,
            address.last
          ].split(", ").compact.join(", ")
        end

        def address_line_1(sub_building_name:, building_name:, building_number:)
          return building_number if building_name.nil?
          return building_name if sub_building_name.nil?

          [sub_building_name, building_name].join(", ")
        end
      end
    end
  end
end
