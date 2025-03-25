require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Practitioner::AnswersPresenter do
  let(:journey) { Journeys::EarlyYearsPayment }
  let(:journey_session) { create(:early_years_payment_practitioner_session, answers:) }
  let(:answers) {
    build(
      :early_years_payment_practitioner_answers,
      first_name: "John",
      surname: "Doe",
      date_of_birth: Date.new(1970, 1, 1),
      national_insurance_number: "QQ123456C",
      address_line_1: "1",
      address_line_2: "Some Street",
      address_line_3: "Some City",
      postcode: "AB1 C23",
      email_address: "practitioner@example.com",
      provide_mobile_number: true,
      mobile_number: "07700900001",
      banking_name: "Mr John Doe",
      bank_account_number: "12345678",
      bank_sort_code: "123456",
      payroll_gender: "dont_know"
    )
  }

  describe "#identity_answers" do
    subject { described_class.new(journey_session).identity_answers }

    context "Full name" do
      it { is_expected.to include(["Full name", "John Doe", "personal-details"]) }
    end

    context "Date of birth" do
      it { is_expected.to include(["Date of birth", "1 January 1970", "personal-details"]) }
    end

    context "National Insurance number" do
      it { is_expected.to include(["National Insurance number", "QQ123456C", "personal-details"]) }
    end

    context "Home address" do
      it { is_expected.to include(["Home address", "1, Some Street, Some City, AB1 C23", "address"]) }
    end

    context "Email address" do
      it { is_expected.to include(["Preferred email address", "practitioner@example.com", "email-address"]) }
    end

    context "Mobile number" do
      it { is_expected.to include(["Provide mobile number?", "Yes", "provide-mobile-number"]) }
      it { is_expected.to include(["Preferred mobile number", "07700900001", "mobile-number"]) }
    end
  end

  describe "#payment_answers" do
    subject { described_class.new(journey_session).payment_answers }

    context "Bank account name" do
      it { is_expected.to include(["Name on the account", "Mr John Doe", "personal-bank-account"]) }
    end

    context "Sort code" do
      it { is_expected.to include(["Sort code", "123456", "personal-bank-account"]) }
    end

    context "Account number" do
      it { is_expected.to include(["Account number", "12345678", "personal-bank-account"]) }
    end

    context "Payroll gender" do
      it { is_expected.to include(["Payroll gender", "Don’t know", "gender"]) }
    end
  end
end
