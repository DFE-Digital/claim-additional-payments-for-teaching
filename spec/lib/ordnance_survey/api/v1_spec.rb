require "rails_helper"

module OrdnanceSurvey
  class Api
    describe V1 do
      subject(:v1) { described_class.new(client: double("client")) }

      describe "#search_places" do
        it "returns SearchPlaces" do
          expect(v1.search_places).to be_an_instance_of(described_class::SearchPlaces)
        end

        it "memoizes SearchPlaces" do
          expect(v1.search_places).to be(v1.search_places)
        end
      end
    end
  end
end
