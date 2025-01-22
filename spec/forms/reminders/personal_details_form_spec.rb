require "rails_helper"

RSpec.describe Reminders::PersonalDetailsForm do
  let!(:journey_configuration) do
    create(:journey_configuration, :further_education_payments)
  end

  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:claim) { create(:claim, :submitted) }
  let(:params) { ActionController::Parameters.new }

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params: params,
      session: {"submitted_claim_id" => claim.id}
    )
  end

  describe "#set_reminder_from_claim" do
    context "when reminder previously soft deleted" do
      let!(:reminder) do
        create(
          :reminder,
          :soft_deleted,
          full_name: claim.full_name,
          email_address: claim.email_address,
          email_verified: true,
          itt_subject: claim.eligible_itt_subject,
          itt_academic_year: journey_configuration.current_academic_year.succ,
          journey_class: journey.to_s
        )
      end

      it "becomes undeleted" do
        expect {
          subject.set_reminder_from_claim
        }.to change { reminder.reload.deleted_at }.to(nil)
      end
    end
  end

  describe "validations" do
    let(:domain) { "@example.com" }

    let(:params) do
      ActionController::Parameters.new(claim: {reminder_email_address: email_address})
    end

    before do
      subject.valid?
    end

    describe "email_address" do
      context "when missing" do
        let(:email_address) { nil }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors.added?(:reminder_email_address, :blank)).to be true
        end
      end

      context "when too long" do
        let(:email_address) { "#{"a" * (130 - domain.length)}#{domain}" }

        it do
          expect(subject).not_to be_valid
          expect(subject.errors.added?(:reminder_email_address, :too_long, count: 129)).to be true
          expect(subject.errors.messages[:reminder_email_address]).to include("Email address must be 129 characters or less")
        end
      end

      context "when as long as it can get" do
        let(:email_address) { "#{"a" * (129 - domain.length)}#{domain}" }

        it do
          expect(subject.errors.added?(:reminder_email_address, :too_long, count: 129)).to be false
        end
      end

      context "when the wrong format" do
        let(:email_address) { "not_an_email" }

        it do
          expect(subject.errors.added?(:reminder_email_address, :invalid, value: "not_an_email")).to be true
        end
      end

      context "when the correct format" do
        let(:email_address) { "test@example.com" }

        it do
          expect(subject.errors.added?(:reminder_email_address, :invalid, value: "not_an_email")).to be false
        end
      end
    end
  end
end
