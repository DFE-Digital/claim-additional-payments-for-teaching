require "rails_helper"

RSpec.describe Claim::Search do
  subject(:search) { Claim::Search.new(query) }

  let!(:other_claim) { create(:claim, :submitted) }

  context "when searching by reference" do
    let(:reference) { "ABC123" }
    let(:claim) { create(:claim, :submitted, reference: reference) }

    let(:query) { "ABC123" }

    it "finds a claim that matches that reference" do
      expect(search.claims).to match_array(claim)
    end

    context "when the reference is lowercase" do
      let(:query) { "abc123" }

      it "finds a claim that matches that reference" do
        expect(search.claims).to match_array(claim)
      end
    end
  end

  context "when searching by email" do
    let(:email) { "foo@example.com" }
    let(:claim) { create(:claim, :submitted, email_address: email) }

    let(:query) { "foo@example.com" }

    it "finds claims that match that email address" do
      expect(search.claims).to match_array(claim)
    end
  end

  context "when searching by surname" do
    let(:surname) { "Wayne" }
    let(:claim) { create(:claim, :submitted, surname: surname) }

    let(:query) { "Wayne" }

    it "finds claims that match that surname" do
      expect(search.claims).to match_array(claim)
    end

    context "when the surname is lowercase" do
      let(:query) { "wayne" }

      it "finds a claim that matches that reference" do
        expect(search.claims).to match_array(claim)
      end
    end
  end

  context "when searching by teacher reference" do
    let(:reference) { "1234567" }
    let(:claim) { create(:claim, :submitted, teacher_reference_number: reference) }

    let(:query) { "1234567" }

    it "finds claims that match that email address" do
      expect(search.claims).to match_array(claim)
    end
  end
end
