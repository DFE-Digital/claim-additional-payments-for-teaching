require "rails_helper"

module OrdnanceSurvey
  RSpec.describe Client::Response do
    subject { described_class.new(response:) }

    let(:body_hash) do
      {
        response: {
          reason_code: "ACODE",
          reason_text: "reasontext",
          key1: "value1"
        }
      }
    end

    let(:response) do
      instance_double(
        Faraday::Response,
        body: body_hash.to_json,
        status: "200"
      )
    end

    describe "#body" do
      it "returns parsed JSON" do
        expect(subject.body).to eq(body_hash)
      end

      context "with empty body" do
        let(:response) { instance_double(Faraday::Response, body: "") }

        it "returns nil" do
          expect(subject.body).to be_nil
        end
      end
    end

    describe "#code" do
      it "returns int" do
        expect(subject.code).to eql 200
      end
    end
  end
end
