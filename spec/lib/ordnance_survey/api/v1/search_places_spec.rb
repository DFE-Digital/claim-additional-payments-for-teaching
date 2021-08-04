require "rails_helper"

module OrdnanceSurvey
  class Api
    class V1
      describe SearchPlaces do
        subject(:search_places) { described_class.new(client: Client.new(base_url: "https://api.os.uk")) }

        describe "#index" do
          subject(:index) { search_places.index(params: params_args) }

          let(:claim) { build(:claim, :submittable, postcode: "SO16 9FX") }

          let(:params_args) do
            {
              postcode: claim.postcode
            }
          end

          let!(:index_endpoint) do
            stub_search_places_index(claim: claim)
          end

          it "makes correct request" do
            index

            expect(index_endpoint).to have_been_requested
          end

          context "with result set containing [:DPA][:BUILDING_NUMBER]" do
            let(:claim) { build(:claim, :submittable, postcode: "SE13 7UN") }

            it "returns an array of address details" do
              expect(index).to eq(
                [
                  {
                    address: "1, WEARSIDE ROAD, LONDON, SE13 7UN",
                    address_line_1: "1",
                    address_line_2: "WEARSIDE ROAD",
                    address_line_3: "LONDON",
                    postcode: "SE13 7UN"
                  },
                  {
                    address: "2, WEARSIDE ROAD, LONDON, SE13 7UN",
                    address_line_1: "2",
                    address_line_2: "WEARSIDE ROAD",
                    address_line_3: "LONDON",
                    postcode: "SE13 7UN"
                  },
                  {
                    address: "38A, WEARSIDE ROAD, LONDON, SE13 7UN",
                    address_line_1: "38A",
                    address_line_2: "WEARSIDE ROAD",
                    address_line_3: "LONDON",
                    postcode: "SE13 7UN"
                  },
                  {
                    address: "38B-38C, WEARSIDE ROAD, LONDON, SE13 7UN",
                    address_line_1: "38B-38C",
                    address_line_2: "WEARSIDE ROAD",
                    address_line_3: "LONDON",
                    postcode: "SE13 7UN"
                  }
                ]
              )
            end
          end

          context "with result set containing [:DPA][:SUB_BUILDING_NAME] and [:DPA][:BUILDING_NAME]" do
            let(:claim) { build(:claim, :submittable, postcode: "SO16 9FX") }

            it "returns an array of address details" do
              expect(index).to eq(
                [
                  {
                    address: "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                    address_line_1: "FLAT 1, MILLBROOK TOWER",
                    address_line_2: "WINDERMERE AVENUE",
                    address_line_3: "SOUTHAMPTON",
                    postcode: "SO16 9FX"
                  },
                  {
                    address: "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                    address_line_1: "FLAT 10, MILLBROOK TOWER",
                    address_line_2: "WINDERMERE AVENUE",
                    address_line_3: "SOUTHAMPTON",
                    postcode: "SO16 9FX"
                  },
                  {
                    address: "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                    address_line_1: "FLAT 11, MILLBROOK TOWER",
                    address_line_2: "WINDERMERE AVENUE",
                    address_line_3: "SOUTHAMPTON",
                    postcode: "SO16 9FX"
                  }
                ]
              )
            end
          end
        end

        describe "#show" do
          subject(:show) { search_places.show(params: params_args) }

          let(:claim) { build(:claim, :submittable, address_line_1: 19, postcode: "BD7 3BE") }

          let(:params_args) do
            {
              address_line_1: claim.address_line_1,
              postcode: claim.postcode
            }
          end

          let!(:show_endpoint) do
            stub_search_places_show(claim: claim)
          end

          it "makes correct request" do
            show

            expect(show_endpoint).to have_been_requested
          end

          context "with a searchable address" do
            it "returns a single address" do
              expect(show).to eq(
                {
                  address: "19, TURNER PLACE, BRADFORD, BD7 3BE",
                  address_line_1: "19",
                  address_line_2: "TURNER PLACE",
                  address_line_3: "BRADFORD",
                  postcode: "BD7 3BE"
                }
              )
            end
          end

          # This arises when the supplied postcode does not match the response postcode
          # and to give a mismatch the param of minmatch of 0.4 was determined to give accurate results
          # in the example tested the results were as follows:
          # "ADDRESS" : "18, WEARSIDE ROAD, LONDON, SE13 7UN" - query: 38 SE137UN, minmatch: 0.2
          # "ADDRESS" : "38, THE WOODLANDS, LONDON, SE13 6TY" - query: 38 SE13 7UN, minmatch: 0.3
          context "with no matches" do
            let(:claim) { build(:claim, :submittable, address_line_1: 38, postcode: "SE13 7UN") }

            before do
              stub_search_places_show(
                claim: claim,
                overrides: {
                  body: {
                    data: nil
                  },
                  status: 200
                }
              )
            end

            it "returns nil" do
              expect(show).to be_nil
            end
          end
        end
      end
    end
  end
end
