require "rails_helper"

RSpec.describe DfeSignIn::UserAccess do
  subject { described_class.new(user_id: 999, organisation_id: 456) }

  let(:url) { "#{DfeSignIn.configuration.base_url}/services/#{DfeSignIn.configuration.client_id}/organisations/456/users/999" }

  before do
    stub_request(:get, url)
      .to_return(body: response.to_json, status: status)
  end

  describe "role_codes" do
    let(:role_ids) { subject.role_codes }
    let(:response) do
      {
        "userId" => "999",
        "serviceId" => "123",
        "organisationId" => "456",
        "roles" => roles,
        "identifiers" => [
          {
            "key" => "identifier-key",
            "value" => "identifier-value",
          },
        ],
      }
    end

    context "with a valid response" do
      let(:status) { 200 }
      let(:roles) do
        [
          {
            "id" => "role-id",
            "name" => "My role",
            "code" => "my_role",
            "numericId" => "9999",
            "status" => {
              "id" => 1,
            },
          },
        ]
      end

      it "returns the role code" do
        expect(role_ids).to eq(["my_role"])
      end
    end

    context "with multiple roles" do
      let(:status) { 200 }
      let(:roles) do
        [
          {
            "id" => "role-id",
            "name" => "My role",
            "code" => "my_role",
            "numericId" => "9999",
            "status" => {
              "id" => 1,
            },
          },
          {
            "id" => "another-role",
            "name" => "Another role",
            "code" => "another_role",
            "numericId" => "1234",
            "status" => {
              "id" => 5,
            },
          },
        ]
      end

      it "returns both role codes" do
        expect(role_ids).to eq(["my_role", "another_role"])
      end
    end

    context "with an invalid response" do
      let(:status) { 500 }
      let(:response) { {"error": "An error occurred"} }

      it "raises an error" do
        expect { role_ids }.to raise_error(
          DfeSignIn::ExternalServerError, "500: {\"error\":\"An error occurred\"}"
        )
      end
    end
  end
end
