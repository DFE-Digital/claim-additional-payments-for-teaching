require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Practitioner::FindReferenceForm do
  subject { described_class.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::EarlyYearsPayment::Practitioner }
  let(:journey_session) { create(:early_years_payment_practitioner_session) }

  let(:reference_number) { nil }
  let(:email) { nil }

  let(:params) do
    ActionController::Parameters.new(claim: {reference_number:, email:})
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
      let(:email) { claim.practitioner_email_address }

      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          reference: "foo",
          practitioner_email_address: "user@example.com"
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
      let(:email) { claim.practitioner_email_address }

      let(:claim) do
        create(
          :claim,
          reference: "foo",
          practitioner_email_address: "user@example.com"
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
