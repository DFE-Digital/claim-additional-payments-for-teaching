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
        national_insurance_number: "AB123456C"
      )
    end

    let!(:claim_2) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "AB123456C"
      )
    end

    let!(:claim_3) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "AB123456C"
      )
    end

    let!(:claim_4) do
      create(
        :claim,
        :submitted,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        national_insurance_number: "AB123456C"
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

  context "search by EY provider details" do
    let!(:provider_1) do
      create(
        :eligible_ey_provider,
        primary_key_contact_email_address: "test1-nursery@example.com"
      )
    end

    let!(:provider_2) do
      create(
        :eligible_ey_provider,
        secondary_contact_email_address: "test2-nursery@example.com"
      )
    end

    let!(:provider_3) do
      create(
        :eligible_ey_provider,
        nursery_name: "Test Nursery"
      )
    end

    let!(:claim_1) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: provider_1.urn
        }
      )
    end

    let!(:claim_2) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: provider_2.urn
        }
      )
    end

    let!(:claim_3) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          nursery_urn: provider_3.urn
        }
      )
    end

    let!(:claim_4) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          provider_email_address: "provider-email-address@example.com",
          nursery_urn: create(:eligible_ey_provider).urn
        }
      )
    end

    let!(:claim_5) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        practitioner_email_address: "pracitioner@example.com",
        eligibility_attributes: {
          nursery_urn: create(:eligible_ey_provider).urn
        }
      )
    end

    subject { search.claims }

    context "when searching for a primary key contact email address" do
      let(:query) { provider_1.primary_key_contact_email_address }

      it { is_expected.to match_array([claim_1]) }
    end

    context "when searching for a secondary key contact email address" do
      let(:query) { provider_2.secondary_contact_email_address }

      it { is_expected.to match_array([claim_2]) }
    end

    context "when searching for a nursery name" do
      let(:query) { provider_3.nursery_name }

      it { is_expected.to match_array([claim_3]) }
    end

    context "when searching for a provider email address" do
      let(:query) { claim_4.eligibility.provider_email_address }

      it { is_expected.to match_array([claim_4]) }
    end

    context "when searching for a practitioner email address" do
      let(:query) { claim_5.practitioner_email_address }

      it { is_expected.to match_array([claim_5]) }
    end
  end
end
