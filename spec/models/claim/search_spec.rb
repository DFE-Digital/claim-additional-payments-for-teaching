require "rails_helper"

RSpec.describe Claim::Search do
  subject(:search) { described_class.new(query) }

  let(:reference) { "abc123" }
  let(:email) { "foo@example.com" }
  let(:surname) { "wayne" }
  let(:teacher_reference_number) { "1234567" }
  let(:matches_nothing) { "blah" }

  before { create(:claim, :submitted) }

  context "search by reference" do
    let(:claim) { create(:claim, :submitted, reference: reference) }

    context "uppercase query" do
      let(:query) { reference.upcase }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "lowercase query" do
      let(:query) { reference.downcase }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "no matches" do
      let(:query) { matches_nothing }

      specify { expect(search.claims).to be_empty }
    end
  end

  context "search by email" do
    let(:claim) { create(:claim, :submitted, email_address: email) }

    context "no matches" do
      let(:query) { matches_nothing }

      specify { expect(search.claims).to be_empty }
    end

    context "one match" do
      context "uppercase query" do
        let(:query) { email.upcase }

        specify { expect(search.claims).to contain_exactly(claim) }
      end

      context "lowercase query" do
        let(:query) { email.downcase }

        specify { expect(search.claims).to contain_exactly(claim) }
      end
    end

    context "multiple matches" do
      let(:historical_matching_claim) { create(:claim, :submitted, email_address: email) }
      let(:query) { email }

      specify { expect(search.claims).to contain_exactly(claim, historical_matching_claim) }
    end
  end

  context "search by surname" do
    let(:claim) { create(:claim, :submitted, surname: surname) }

    context "uppercase query" do
      let(:query) { surname.upcase }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "lowercase query" do
      let(:query) { surname.downcase }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "no matches" do
      let(:query) { matches_nothing }

      specify { expect(search.claims).to be_empty }
    end

    context "multiple matches" do
      let(:historical_matching_claim) { create(:claim, :submitted, surname: surname) }
      let(:query) { surname }

      specify { expect(search.claims).to contain_exactly(claim, historical_matching_claim) }
    end
  end

  context "search by teacher reference number" do
    let(:claim) { create(:claim, :submitted, teacher_reference_number: teacher_reference_number) }

    context "matches" do
      let(:query) { teacher_reference_number }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "no matches" do
      let(:query) { matches_nothing }

      specify { expect(search.claims).to be_empty }
    end

    context "multiple matches" do
      let(:historical_matching_claim) { create(:claim, :submitted, teacher_reference_number: teacher_reference_number) }
      let(:query) { teacher_reference_number }

      specify { expect(search.claims).to contain_exactly(claim, historical_matching_claim) }
    end
  end
end
