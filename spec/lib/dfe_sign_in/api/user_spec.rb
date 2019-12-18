require "rails_helper"

RSpec.describe DfeSignIn::Api::User do
  describe "#all" do
    let(:users) { described_class.all }

    context "with one page" do
      before do
        stub_dfe_sign_in_user_list_request
      end

      it "gets all the users" do
        expect(users.count).to eq(3)
        expect(users.first.organisation_id).to eq("5b0e38fc-1db7-11ea-978f-2e728ce88125")
        expect(users.first.organisation_name).to eq("ACME Inc")
        expect(users.first.user_id).to eq("5b0e3686-1db7-11ea-978f-2e728ce88125")
        expect(users.first.given_name).to eq("Alice")
        expect(users.first.family_name).to eq("Example")
        expect(users.first.email).to eq("alice@example.com")

        expect(users.second.given_name).to eq("Bob")

        expect(users.third.given_name).to eq("Eve")
      end
    end

    context "with multiple pages" do
      let!(:first_page_stub) { stub_dfe_sign_in_user_list_request(number_of_pages: 3) }
      let!(:second_page_stub) { stub_dfe_sign_in_user_list_request(number_of_pages: 3, page_number: 2) }
      let!(:third_page_stub) { stub_dfe_sign_in_user_list_request(number_of_pages: 3, page_number: 3) }

      it "gets all the users from all of the pages" do
        expect(users.count).to eq(9)

        expect(first_page_stub).to have_been_requested
        expect(second_page_stub).to have_been_requested
        expect(third_page_stub).to have_been_requested
      end
    end
  end

  let(:user) { described_class.new(user_id: 999, organisation_id: 456) }

  context "with a valid response" do
    before do
      stub_dfe_sign_in_user_info_request(999, 456, "my_role")
    end

    describe "#has_role?" do
      it "returns true when the user has the role" do
        expect(user.has_role?("my_role")).to eq(true)
      end

      it "returns false when a role does not exist" do
        expect(user.has_role?("other_role")).to eq(false)
      end
    end

    describe "#role_codes" do
      it "returns the role codes" do
        expect(user.role_codes).to eq(["my_role"])
      end
    end
  end

  context "with an invalid response" do
    before do
      stub_failed_dfe_sign_in_user_info_request(999, 456)
    end

    it "raises an error" do
      expect {
        user.has_role?("my_role")
      }.to raise_error(
        DfeSignIn::ExternalServerError, "500: {\"error\":\"An error occurred\"}"
      )
    end
  end
end
