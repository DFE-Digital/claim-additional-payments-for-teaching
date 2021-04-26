require "rails_helper"

module Dqt
  describe Client::Response do
    subject(:response) { described_class.new(response: response_args) }

    let(:body_args) do
      {
        response: {
          reason_code: "ACODE",
          reason_text: "reasontext",
          key1: "value1"
        }
      }
    end

    let(:response_args) do
      instance_double(
        Net::HTTPResponse,
        body: body_args.to_json
      )
    end

    describe "#body" do
      it "returns parsed JSON" do
        expect(response.body).to eq(body_args)
      end

      it "memoizes parsed JSON" do
        expect(response.body).to be(response.body)
      end

      context "with empty body" do
        let(:response_args) { instance_double(Net::HTTPResponse, body: "") }

        it "returns nil" do
          expect(response.body).to eq(nil)
        end
      end
    end

    describe "#code" do
      it { is_expected.to delegate_method(:code).to(:response) }
    end
  end
end
