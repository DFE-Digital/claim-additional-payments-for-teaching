require "rails_helper"

RSpec.describe "Claims" do
  describe "#create" do
    before do
      create(:journey_configuration, :targeted_retention_incentive_payments)
      start_claim("targeted-retention-incentive-payments")
    end

    let(:submit_form) { put reminder_path(journey: "targeted-retention-incentive-payments", slug: "personal-details", params: form_params) }

    context "with full name and valid email address" do
      let(:form_params) { {claim: {reminder_full_name: "Joe Bloggs", reminder_email_address: "joe.bloggs@example.com"}} }

      it "redirects to /email-verfication slug" do
        submit_form
        expect(response).to redirect_to("/targeted-retention-incentive-payments/reminders/email-verification")
      end
    end

    context "with empty form" do
      let(:form_params) { {claim: {reminder_full_name: "", reminder_email_address: ""}} }

      before { submit_form }

      it "renders errors containing full name required" do
        expect(response.body).to include "Enter full name"
      end

      it "renders errors containing email address required" do
        expect(response.body).to include "Enter an email address"
      end
    end

    context "invalid email address" do
      let(:form_params) { {claim: {reminder_full_name: "Joe Bloggs", reminder_email_address: "joe.bloggs.example.com"}} }

      it "renders errors containing invalid email address" do
        submit_form
        expect(response.body).to include "Enter an email address in the correct format, like name@example.com"
      end
    end

    context "Notify returns an unknown error" do
      let(:form_params) { {claim: {reminder_full_name: "Joe Bloggs", reminder_email_address: "joe.bloggs@example.com"}} }

      let(:mailer) { double("notify") }
      let(:notifications_error_response) { double("response", code: 400, body: "Something unexpected") }

      before do
        allow(mailer).to receive(:deliver_now).and_raise(Notifications::Client::BadRequestError, notifications_error_response)
        allow(ReminderMailer).to receive(:email_verification).and_return(mailer)
      end

      it "renders errors containing team only API key" do
        expect { submit_form }.to raise_error(Notifications::Client::BadRequestError, "Something unexpected")
      end
    end
  end

  # Rollbar error - confirmation page loaded without reminder that can be loaded from the session information
  describe "#show" do
    describe "for FurtherEducationPayments journey" do
      before do
        create(:journey_configuration, :further_education_payments)
      end

      let(:journey) { Journeys::FurtherEducationPayments }

      subject { get reminder_path(journey: journey.routing_name.to_sym, slug: "confirmation") }

      it { is_expected.to redirect_to(journey.start_page_url) }
    end

    describe "for TargetedRetentionIncentivePayments journey" do
      before do
        create(:journey_configuration, :targeted_retention_incentive_payments)
      end

      let(:journey) { Journeys::TargetedRetentionIncentivePayments }

      subject { get reminder_path(journey: journey.routing_name.to_sym, slug: "confirmation") }

      it { is_expected.to redirect_to(journey.start_page_url) }
    end
  end
end
