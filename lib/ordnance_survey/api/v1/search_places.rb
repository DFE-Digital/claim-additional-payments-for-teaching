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

          return nil unless response

          response[:results].map do |result|
            {
              address: result[:DPA][:ADDRESS],
              address_line_1: address_line_1(sub_building_name: result[:DPA][:SUB_BUILDING_NAME], building_name: result[:DPA][:BUILDING_NAME]),
              address_line_2: result[:DPA][:THOROUGHFARE_NAME],
              address_line_4: result[:DPA][:POST_TOWN],
              postcode: result[:DPA][:POSTCODE]
            }
          end
        end

        def show(params:)
          mapped_params = {
            query: [params[:address_line_1], params[:postcode].delete(" ")].join(", "),
            maxresults: 1
          }

          response = client.get(path: "/search/places/v1/find", params: mapped_params)

          return nil unless response

          first_item = response[:results].first[:DPA]

          {
            address: first_item[:ADDRESS],
            address_line_1: first_item[:BUILDING_NUMBER],
            address_line_2: first_item[:THOROUGHFARE_NAME],
            address_line_4: first_item[:POST_TOWN],
            postcode: first_item[:POSTCODE]
          }
        end

        private

        attr_accessor :client

        def address_line_1(sub_building_name:, building_name:)
          return building_name if sub_building_name.nil?

          [sub_building_name, building_name].join(", ")
        end
      end
    end
  end
end
