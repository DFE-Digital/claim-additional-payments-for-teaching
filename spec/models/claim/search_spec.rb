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
    let!(:claim) { create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: teacher_reference_number}) }

    context "matches" do
      let(:query) { teacher_reference_number }

      specify { expect(search.claims).to contain_exactly(claim) }
    end

    context "no matches" do
      let(:query) { matches_nothing }

      specify { expect(search.claims).to be_empty }
    end

    context "multiple matches" do
      let!(:historical_matching_claim) { create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: teacher_reference_number}) }
      let(:query) { teacher_reference_number }

      specify { expect(search.claims).to contain_exactly(claim, historical_matching_claim) }
    end
  end

  context "search by payment id" do
    let!(:claim_1) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "QQ123456C"
      )
    end

    let!(:claim_2) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "QQ123456C"
      )
    end

    let!(:claim_3) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "QQ123456C"
      )
    end

    let!(:claim_4) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "QQ123456C"
      )
    end

    let!(:payment_1) { create(:payment, claims: [claim_1, claim_2]) }

    let!(:payment_2) do
      create(:payment, claims: [claim_3], payroll_run: payment_1.payroll_run)
    end

    let(:query) { payment_1.id }

    subject { search.claims }

    it { is_expected.to include(claim_1) }
    it { is_expected.to include(claim_2) }
    it { is_expected.not_to include(claim_3) }
    it { is_expected.not_to include(claim_4) }
  end
end
