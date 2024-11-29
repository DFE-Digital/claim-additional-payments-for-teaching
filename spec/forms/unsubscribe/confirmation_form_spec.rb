require "rails_helper"

RSpec.describe Unsubscribe::ConfirmationForm do
  describe "#obfuscasted_email" do
    let(:reminder) {
      create(
        :reminder,
        email_address:
      )
    }

    subject { described_class.new(id: reminder.id) }

    context "happy path" do
      let(:email_address) { "hello@example.com" }

      it "obfuscates" do
        expect(subject.obfuscasted_email).to eql "h***o@example.com"
      end
    end

    context "1 char email" do
      let(:email_address) { "h@example.com" }

      it "obfuscates" do
        expect(subject.obfuscasted_email).to eql "*@example.com"
      end
    end

    context "2 char email" do
      let(:email_address) { "hh@example.com" }

      it "obfuscates" do
        expect(subject.obfuscasted_email).to eql "**@example.com"
      end
    end

    context "3 char email" do
      let(:email_address) { "hah@example.com" }

      it "obfuscates" do
        expect(subject.obfuscasted_email).to eql "***@example.com"
      end
    end
  end
end
