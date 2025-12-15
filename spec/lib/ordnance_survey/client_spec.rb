require "rails_helper"

module OrdnanceSurvey
  RSpec.describe Client do
    shared_examples "a request" do |method|
      it "makes a request to a host" do
        stub = stub_request(method, "https://www.example.com")
        client.public_send(method)

        expect(stub).to have_been_requested
      end

      it "adds content type header" do
        stub = stub_request(method, "https://www.example.com").with(
          headers: {
            "Content-Type": "application/json"
          }
        )

        client.public_send(method)

        expect(stub).to have_been_requested
      end

      context "with JSON body" do
        before do
          stub_request(method, "https://www.example.com").to_return(
            body: body_args.to_json
          )
        end

        let(:body_args) do
          {
            response: {
              reason_code: "ACODE",
              reason_text: "sometext",
              key1: "value1"
            }
          }
        end

        it "translates response into Ruby" do
          expect(client.public_send(method)).to eq(body_args)
        end
      end

      context "with empty body" do
        before { stub_request(method, "https://www.example.com").to_return(body: "") }

        it "translates response into Ruby" do
          expect(client.public_send(method)).to eq(nil)
        end
      end

      context "with not found status" do
        before { stub_request(method, "https://www.example.com").to_return(status: 404) }

        it "returns nil" do
          expect(client.public_send(method)).to eq(nil)
        end
      end

      context "with invalid response status" do
        let(:response_status) { [*0..199, *300..403, *405..599].sample }

        before { stub_request(method, "https://www.example.com").to_return(status: response_status) }

        it "raises an error" do
          expect { client.public_send(method) }.to raise_error(Client::ResponseError)
        end
      end

      context "with client params" do
        before { client_args[:params] = {some_param: "somevalue"} }

        it "makes a request with those params" do
          stub = stub_request(method, "https://www.example.com").with(
            query: hash_including({some_param: "somevalue"})
          )

          client.public_send(method)

          expect(stub).to have_been_requested
        end
      end

      context "without config params" do
        before { client_args[:params] = nil }

        it "makes a request without those params" do
          stub = stub_request(method, "https://www.example.com").with(query: nil)

          client.public_send(method)

          expect(stub).to have_been_requested
        end
      end
    end

    subject(:client) { described_class.new(**client_args) }

    let(:client_args) do
      {
        base_url: "https://www.example.com/test",
        params: {}
      }
    end

    describe "#api" do
      it "returns API" do
        expect(client.api).to be_an_instance_of(Api)
      end

      it "memoizes API" do
        expect(client.api).to equal(client.api)
      end
    end

    describe "#get" do
      it_behaves_like "a request", :get

      it "adds params to URL" do
        stub = stub_request(:get, "https://www.example.com").with(
          query: hash_including({
            test: "value"
          })
        )

        client.get(params: {test: "value"})

        expect(stub).to have_been_requested
      end

      it "should not send body" do
        stub = stub_request(:get, "https://www.example.com").with(
          body: nil
        )

        client.get

        expect(stub).to have_been_requested
      end

      context "with body param" do
        let(:params) { {body: "something"} }

        it "raises an error" do
          expect { client.get(params) }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
