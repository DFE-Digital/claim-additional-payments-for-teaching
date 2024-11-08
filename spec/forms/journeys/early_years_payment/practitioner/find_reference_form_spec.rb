require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Practitioner::FindReferenceForm do
  subject { described_class.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::EarlyYearsPayment::Practitioner }
  let(:journey_session) { create(:early_years_payment_practitioner_session) }

  let(:reference_number) { nil }

  let(:eligible_ey_provider) { create(:eligible_ey_provider) }

  let(:params) do
    ActionController::Parameters.new(claim: {reference_number:})
  end

  describe "validations" do
    context "when reference number blank" do
      it "is not valid" do
        expect(subject).to be_invalid
        expect(subject.errors[:reference_number]).to be_present
      end
    end

    context "when EY claim" do
      let(:reference_number) { claim.reference }

      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          reference: "foo"
        )
      end

      it "is valid" do
        expect(subject).to be_valid
        expect(subject.errors[:reference_number]).to be_blank
      end
    end
  end

  describe "#save" do
    let(:reference_number) { claim.reference }

    let(:claim) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        eligibility: build(:early_years_payments_eligibility, nursery_urn: eligible_ey_provider.urn),
        reference: "foo"
      )
    end

    it "updates reference number in session" do
      expect {
        subject.save
      }.to change { journey_session.reload.answers.reference_number }.from(nil).to(reference_number)
    end

    it "updates reference_number_found in session" do
      expect {
        subject.save
      }.to change { journey_session.reload.answers.reference_number_found }.from(nil).to(true)
    end

    it "updates nursery_name in session" do
      expect {
        subject.save
      }.to change { journey_session.reload.answers.nursery_name }.from(nil).to(eligible_ey_provider.nursery_name)
    end

    it "sets practitioner_claim_started_at" do
      expect {
        subject.save
      }.to change { journey_session.reload.answers.practitioner_claim_started_at }.from(nil)
    end

    context "when the claim has only been submitted by the provider, not the practitioner" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          eligibility: build(:early_years_payments_eligibility, :provider_claim_submitted, nursery_urn: eligible_ey_provider.urn),
          reference: "foo"
        )
      end

      it "sets claim_already_submitted to false in session" do
        expect {
          subject.save
        }.to change { journey_session.reload.answers.claim_already_submitted }.from(nil).to(false)
      end
    end

    context "when the claim has been submitted by the practitioner already" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsPayments,
          eligibility: build(:early_years_payments_eligibility, nursery_urn: eligible_ey_provider.urn),
          reference: "foo"
        )
      end

      it "sets claim_already_submitted in session" do
        expect {
          subject.save
        }.to change { journey_session.reload.answers.claim_already_submitted }.from(nil).to(true)
      end
    end

    context "when reference is a random string" do
      let(:reference_number) { "foo" }

      it "updates reference_number_found in session" do
        expect {
          subject.save
        }.to change { journey_session.reload.answers.reference_number_found }.from(nil).to(false)
      end
    end

    context "when reference is a non EY claim" do
      let(:reference_number) { claim.reference }

      let(:claim) do
        create(
          :claim,
          reference: "foo"
        )
      end

      it "updates reference_number_found in session" do
        expect {
          subject.save
        }.to change { journey_session.reload.answers.reference_number_found }.from(nil).to(false)
      end
    end
  end
end
