require "rails_helper"

RSpec.describe "Claims" do
  describe "#create" do
    let(:submit_form) { post reminders_path("additional-payments", params: form_params) }

    context "with full name and valid email address" do
      let(:form_params) { {reminder: {full_name: "Joe Bloggs", email_address: "joe.bloggs@example.com"}} }

      it "redirects to /email-verfication slug" do
        submit_form
        expect(response).to redirect_to("/additional-payments/reminders/email-verification")
      end
    end

    context "with empty form" do
      let(:form_params) { {reminder: {full_name: "", email_address: ""}} }

      before { submit_form }

      it "renders errors containing full name required" do
        expect(response.body).to include "Enter full name"
      end

      it "renders errors containing email address required" do
        expect(response.body).to include "Enter an email address"
      end
    end

    context "invalid email address" do
      let(:form_params) { {reminder: {full_name: "Joe Bloggs", email_address: "joe.bloggs.example.com"}} }

      it "renders errors containing invalid email address" do
        submit_form
        expect(response.body).to include "Enter an email address in the correct format, like name@example.com"
      end
    end

    context "Notify returns an error about email address is required" do
      let(:form_params) { {reminder: {full_name: "Joe Bloggs", email_address: "joe.bloggs@example.com"}} }

      let(:mailer) { double("notify") }
      let(:notifications_error_response) { double("response", code: 400, body: "ValidationError: email_address is a required property") }

      before do
        allow(mailer).to receive(:deliver_now).and_raise(Notifications::Client::BadRequestError, notifications_error_response)
        allow(ReminderMailer).to receive(:email_verification).and_return(mailer)
      end

      it "renders errors containing invalid email address" do
        submit_form
        expect(response.body).to include "Enter an email address in the correct format, like name@example.com"
      end
    end

    context "Notify returns an error about team only API key" do
      let(:form_params) { {reminder: {full_name: "Joe Bloggs", email_address: "joe.bloggs@example.com"}} }

      let(:mailer) { double("notify") }
      let(:notifications_error_response) { double("response", code: 400, body: "BadRequestError: Can’t send to this recipient using a team-only API key") }

      before do
        allow(mailer).to receive(:deliver_now).and_raise(Notifications::Client::BadRequestError, notifications_error_response)
        allow(ReminderMailer).to receive(:email_verification).and_return(mailer)
      end

      it "renders errors containing team only API key" do
        submit_form
        expect(response.body).to include "Only authorised email addresses can be used when using a team-only API key"
      end
    end

    context "Notify returns an unknown error" do
      let(:form_params) { {reminder: {full_name: "Joe Bloggs", email_address: "joe.bloggs@example.com"}} }

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
end
