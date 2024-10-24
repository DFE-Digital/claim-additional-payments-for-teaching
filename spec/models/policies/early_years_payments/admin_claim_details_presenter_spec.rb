require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::AdminClaimDetailsPresenter do
  let(:provider_submitted_claim) do
    build(
      :claim,
      policy: Policies::EarlyYearsPayments,
      reference: "AB123456",
      first_name: "Bruce",
      surname: "Wayne",
      email_address: nil,
      mobile_number: nil,
      practitioner_email_address: "practitioner@example.com",
      paye_reference: "123/A",
      provider_contact_name: "John Doe",
      eligibility_attributes: {
        nursery_urn: eligible_ey_provider.urn,
        start_date: Date.new(2020, 1, 1),
        child_facing_confirmation_given: true,
        provider_email_address: "provider@example.com",
        returning_within_6_months: true,
        returner_worked_with_children: false,
        returner_contract_type: "casual or temporary",
        provider_claim_submitted_at: Date.new(2020, 1, 2),
        award_amount: 1000
      }
    )
  end
  let(:eligible_ey_provider) { create(:eligible_ey_provider) }
  let(:practitioner_submitted_claim) do
    build(
      :claim,
      policy: Policies::EarlyYearsPayments,
      reference: "AB234567",
      first_name: "Bruce",
      surname: "Wayne",
      national_insurance_number: "QQ123456C",
      email_address: "test@example.com",
      mobile_number: "07700900000",
      practitioner_email_address: "practitioner@example.com",
      address_line_1: "Flat 1",
      address_line_2: "1 Test Road",
      address_line_3: "Test Town",
      postcode: "AB1 2CD",
      date_of_birth: Date.new(1901, 1, 1),
      paye_reference: "123/A",
      provider_contact_name: "John Doe",
      submitted_at: Date.new(2020, 1, 4),
      eligibility_attributes: {
        nursery_urn: eligible_ey_provider.urn,
        start_date: Date.new(2020, 1, 1),
        child_facing_confirmation_given: true,
        returning_within_6_months: true,
        returner_worked_with_children: false,
        provider_claim_submitted_at: Date.new(2020, 1, 2),
        award_amount: 1000,
        practitioner_claim_started_at: Date.new(2020, 1, 3)
      }
    )
  end

  before { travel_to Date.new(2020, 2, 1) }

  describe "#personal_details" do
    subject { described_class.new(claim).personal_details }

    context "for a provider submitted claim" do
      let(:claim) { provider_submitted_claim }

      it "returns an array of questions and answers" do
        expected_answers = [
          [I18n.t("early_years_payments.govuk_verify_fields.full_name").capitalize, "Bruce Wayne"],
          [I18n.t("govuk_verify_fields.date_of_birth").capitalize, nil],
          [I18n.t("admin.national_insurance_number"), nil],
          [I18n.t("govuk_verify_fields.address").capitalize, ""],
          [I18n.t("early_years_payments.admin.email_address"), nil],
          [I18n.t("early_years_payments.admin.practitioner_email_address"), "practitioner@example.com"],
          [I18n.t("admin.mobile_number"), nil],
          [I18n.t("early_years_payments.admin.nursery_name"), eligible_ey_provider.nursery_name],
          [I18n.t("early_years_payments.admin.start_date"), I18n.l(claim.eligibility.start_date)],
          [I18n.t("early_years_payments.admin.paye_reference"), "123/A"]
        ]

        expect(subject).to eq expected_answers
      end
    end

    context "for a practitioner submitted claim" do
      let(:claim) { practitioner_submitted_claim }

      it "returns an array of questions and answers" do
        expected_answers = [
          [I18n.t("early_years_payments.govuk_verify_fields.full_name").capitalize, "Bruce Wayne"],
          [I18n.t("govuk_verify_fields.date_of_birth").capitalize, "01/01/1901"],
          [I18n.t("admin.national_insurance_number"), "QQ123456C"],
          [I18n.t("govuk_verify_fields.address").capitalize, "Flat 1<br>1 Test Road<br>Test Town<br>AB1 2CD"],
          [I18n.t("early_years_payments.admin.email_address"), "test@example.com"],
          [I18n.t("early_years_payments.admin.practitioner_email_address"), "practitioner@example.com"],
          [I18n.t("admin.mobile_number"), "07700900000"],
          [I18n.t("early_years_payments.admin.nursery_name"), eligible_ey_provider.nursery_name],
          [I18n.t("early_years_payments.admin.start_date"), I18n.l(claim.eligibility.start_date)],
          [I18n.t("early_years_payments.admin.paye_reference"), "123/A"]
        ]

        expect(subject).to eq expected_answers
      end
    end
  end

  describe "#provider_details" do
    subject { described_class.new(claim).provider_details }

    let(:claim) { provider_submitted_claim }

    it "returns an array of questions and answers" do
      expected_answers = [
        [I18n.t("early_years_payments.admin.provider_email_address"), "provider@example.com"],
        [I18n.t("early_years_payments.admin.provider_name"), "John Doe"],
        [I18n.t("early_years_payments.admin.consent_given"), "Confirmed"],
        [I18n.t("early_years_payments.admin.child_facing_confirmation_given"), "Yes"],
        [I18n.t("early_years_payments.admin.returning_within_6_months"), "Yes"],
        [I18n.t("early_years_payments.admin.returner_worked_with_children"), "No"],
        [I18n.t("early_years_payments.admin.returner_contract_type"), "casual or temporary"]
      ]

      expect(subject).to eq expected_answers
    end
  end

  describe "#submission_details" do
    subject { described_class.new(claim).submission_details }

    context "for a provider submitted claim" do
      let(:claim) { provider_submitted_claim }

      it "returns an array of details" do
        expected_details = [
          [I18n.t("early_years_payments.admin.started_at"), I18n.l(claim.started_at)],
          [I18n.t("early_years_payments.admin.provider_submitted_at"), I18n.l(claim.eligibility.provider_claim_submitted_at)],
          [I18n.t("early_years_payments.admin.practitioner_started_at"), nil],
          [I18n.t("early_years_payments.admin.submitted_at"), nil],
          [I18n.t("admin.decision_deadline"), nil],
          [I18n.t("admin.decision_overdue"), nil]
        ]

        expect(subject).to eq expected_details
      end
    end

    context "for a practitioner submitted claim" do
      let(:claim) { practitioner_submitted_claim }

      it "returns an array of details" do
        expected_details = [
          [I18n.t("early_years_payments.admin.started_at"), I18n.l(claim.started_at)],
          [I18n.t("early_years_payments.admin.provider_submitted_at"), I18n.l(claim.eligibility.provider_claim_submitted_at)],
          [I18n.t("early_years_payments.admin.practitioner_started_at"), I18n.l(claim.eligibility.practitioner_claim_started_at)],
          [I18n.t("early_years_payments.admin.submitted_at"), I18n.l(claim.submitted_at)],
          [I18n.t("admin.decision_deadline"), I18n.l(claim.decision_deadline_date)],
          [I18n.t("admin.decision_overdue"), "N/A"]
        ]

        expect(subject).to eq expected_details
      end

      context "when near the decision deadline" do
        before { travel_to claim.decision_deadline_date - 1.week }

        it "shows the days left until the deadline" do
          expect(subject).to include(
            [I18n.t("admin.decision_overdue"), "<strong class=\"govuk-tag tag--information\">7 days</strong>"]
          )
        end
      end
    end
  end

  describe "#policy_options_provided" do
    subject { described_class.new(claim).policy_options_provided }

    let(:claim) { practitioner_submitted_claim }

    it "returns an array with the eligibility award amount" do
      expected_details = [
        [I18n.t("early_years_payments.policy_full_name"), "£1,000"]
      ]

      expect(subject).to eq expected_details
    end
  end
end
