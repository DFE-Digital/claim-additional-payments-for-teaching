require "rails_helper"

module Dqt
  describe Api do
    subject(:api) { described_class.new(client: double("client")) }

    it { should delegate_method(:qualified_teaching_status).to(:v1) }

    describe "#v1" do
      it "returns V1" do
        expect(api.v1).to be_an_instance_of(described_class::V1)
      end

      it "memoizes V1" do
        expect(api.v1).to be(api.v1)
      end
    end
  end
end
