require "rails_helper"

module OrdnanceSurvey
  describe Configuration do
    subject(:configuration) { described_class.new }

    describe "#client" do
      it "returns same Client instance" do
        expect(configuration.client)
          .to be_an_instance_of(described_class::Client)
          .and equal(configuration.client)
      end
    end
  end
end
