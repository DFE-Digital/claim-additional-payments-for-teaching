# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::Eligibility do
  let(:eligibility) { build(:early_years_payments_eligibility, :eligible) }

  describe "#employment_task_available_at" do
    subject { eligibility.employment_task_available_at }

    it { is_expected.to eq eligibility.start_date + 6.months }
  end

  describe "#employment_task_available?" do
    subject { eligibility.employment_task_available? }

    context "before 6 months from start date" do
      it do
        travel_to(eligibility.start_date) do
          is_expected.to be_falsey
        end
      end
    end

    context "exactly 6 months from start date" do
      it do
        travel_to(eligibility.start_date + 6.months - 2.hours) do
          is_expected.to be_falsey
        end
      end
    end

    context "after 6 months from start date" do
      it do
        travel_to(eligibility.start_date + 6.months + 2.hours) do
          is_expected.to be_truthy
        end
      end
    end
  end

  describe "#practitioner_and_provider_entered_names_match?" do
    subject { eligibility.practitioner_and_provider_entered_names_match? }

    before do
      eligibility.claim = build(
        :claim, :with_onelogin_idv_data,
        onelogin_idv_first_name: claim_first_name,
        onelogin_idv_last_name: claim_last_name
      )

      eligibility.practitioner_first_name = provider_entered_first_name
      eligibility.practitioner_surname = provider_entered_surname
    end

    context "when both first name and surname match exactly" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { "John" }
      let(:provider_entered_surname) { "Smith" }

      it { is_expected.to be true }
    end

    context "when both first name and surname match with different casing" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { "JOHN" }
      let(:provider_entered_surname) { "SMITH" }

      it { is_expected.to be true }
    end

    context "when both first name and surname match with extra whitespace" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { " John " }
      let(:provider_entered_surname) { " Smith " }

      it { is_expected.to be true }
    end

    context "when first name matches but surname does not" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { "John" }
      let(:provider_entered_surname) { "Jones" }

      it { is_expected.to be false }
    end

    context "when surname matches but first name does not" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { "James" }
      let(:provider_entered_surname) { "Smith" }

      it { is_expected.to be false }
    end

    context "when neither first name nor surname match" do
      let(:claim_first_name) { "John" }
      let(:claim_last_name) { "Smith" }
      let(:provider_entered_first_name) { "James" }
      let(:provider_entered_surname) { "Jones" }

      it { is_expected.to be false }
    end
  end

  describe "#practitioner_and_provider_entered_names_partial_match?" do
    subject { eligibility.practitioner_and_provider_entered_names_partial_match? }

    before do
      eligibility.claim = build(
        :claim, :with_onelogin_idv_data,
        onelogin_idv_first_name: onelogin_idv_first_name,
        onelogin_idv_last_name: onelogin_idv_last_name
      )

      eligibility.practitioner_first_name = provider_entered_first_name
      eligibility.practitioner_surname = provider_entered_surname
    end

    context "when both first name and surname match exactly" do
      let(:onelogin_idv_first_name) { "John" }
      let(:onelogin_idv_last_name) { "Smith" }
      let(:provider_entered_first_name) { "John" }
      let(:provider_entered_surname) { "Smith" }

      it { is_expected.to be true }
    end

    context "when both first name and surname match with different casing" do
      let(:onelogin_idv_first_name) { "John" }
      let(:onelogin_idv_last_name) { "Smith" }
      let(:provider_entered_first_name) { "JOHN" }
      let(:provider_entered_surname) { "SMITH" }

      it { is_expected.to be true }
    end

    context "when first name matches but surname does not" do
      let(:onelogin_idv_first_name) { "John" }
      let(:onelogin_idv_last_name) { "Smith" }
      let(:provider_entered_first_name) { "John" }
      let(:provider_entered_surname) { "Jones" }

      it { is_expected.to be true }
    end

    context "when surname matches but first name does not" do
      let(:onelogin_idv_first_name) { "John" }
      let(:onelogin_idv_last_name) { "Smith" }
      let(:provider_entered_first_name) { " James " }
      let(:provider_entered_surname) { "Smith" }

      it { is_expected.to be true }
    end

    context "when neither first name nor surname match" do
      let(:onelogin_idv_first_name) { "John" }
      let(:onelogin_idv_last_name) { "Smith" }
      let(:provider_entered_first_name) { "James" }
      let(:provider_entered_surname) { "Jones" }

      it { is_expected.to be false }
    end
  end
end
