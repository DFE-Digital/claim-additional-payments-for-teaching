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

          it "returns an array of address details" do
            expect(index).to eq(
              [
                {
                  address: "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                  address_line_1: "FLAT 1, MILLBROOK TOWER",
                  address_line_2: "WINDERMERE AVENUE",
                  address_line_4: "SOUTHAMPTON",
                  postcode: "SO16 9FX"
                },
                {
                  address: "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                  address_line_1: "FLAT 10, MILLBROOK TOWER",
                  address_line_2: "WINDERMERE AVENUE",
                  address_line_4: "SOUTHAMPTON",
                  postcode: "SO16 9FX"
                },
                {
                  address: "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                  address_line_1: "FLAT 11, MILLBROOK TOWER",
                  address_line_2: "WINDERMERE AVENUE",
                  address_line_4: "SOUTHAMPTON",
                  postcode: "SO16 9FX"
                }
              ]
            )
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

          it "returns a single address" do
            expect(show).to eq(
              {
                address: "19, TURNER PLACE, BRADFORD, BD7 3BE",
                address_line_1: "19",
                address_line_2: "TURNER PLACE",
                address_line_4: "BRADFORD",
                postcode: "BD7 3BE"
              }
            )
          end
        end
      end
    end
  end
end
