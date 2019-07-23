require "rails_helper"

RSpec.describe DfeSignIn::UserAccess do
  subject { described_class.new(user_id: 999, organisation_id: 456) }

  describe "call" do
    let(:url) { "#{ENV["DFE_SIGN_IN_API_ENDPOINT"]}/services/#{ENV["DFE_SIGN_IN_API_CLIENT_ID"]}/organisations/456/users/999" }

    before do
      stub_request(:get, url)
        .to_return(body: response.to_json, status: status)
    end

    context "with a valid response" do
      let(:status) { 200 }
      let(:response) do
        {
          "userId" => "999",
          "serviceId" => "123",
          "organisationId" => "456",
          "roles" => [
            {
              "id" => "role-id",
              "name" => "The name of the role",
              "code" => "The code of the role",
              "numericId" => "9999",
              "status" => {
                "id" => 1,
              },
            },
          ],
          "identifiers" => [
            {
              "key" => "identifier-key",
              "value" => "identifier-value",
            },
          ],
        }
      end

      it "returns the expected data" do
        expect(subject.call.body).to eq(response)
      end
    end

    context "with an invalid response" do
      let(:status) { 500 }
      let(:response) { {} }

      it "raises an error" do
        expect { subject.call }.to raise_error(DfeSignIn::ExternalServerError)
      end
    end
  end
end
