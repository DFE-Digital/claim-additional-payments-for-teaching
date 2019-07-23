require "rails_helper"

RSpec.describe DfeSignIn::UserAccess do
  subject { described_class.new(user_id: 999, organisation_id: 456) }

  let(:url) { "#{DfeSignIn.configuration.base_url}/services/#{DfeSignIn.configuration.client_id}/organisations/456/users/999" }

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
            "name" => "My role",
            "code" => "my_role",
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

    describe "has_role?" do
      let(:has_role?) { subject.has_role?(role) }

      context "when a role exists" do
        let(:role) { "my_role" }
        it { expect(has_role?).to eq(true) }
      end

      context "when a role does not exist" do
        let(:role) { "other_role" }
        it { expect(has_role?).to eq(false) }
      end
    end
  end

  context "with an invalid response" do
    let(:status) { 500 }
    let(:response) { {} }

    describe "has_role?" do
      it "raises an error" do
        expect { subject.has_role?("my_role") }.to raise_error(DfeSignIn::ExternalServerError)
      end
    end
  end
end
