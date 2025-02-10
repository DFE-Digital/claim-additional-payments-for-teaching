require "rails_helper"
require "csv"

RSpec.describe Claim::DataReportRequest do
  subject { described_class.new(claims) }

  let(:csv) { CSV.parse(subject.to_csv, headers: true) }

  describe "#to_csv" do
    context "original policies" do
      let(:claims) do
        [
          create(:claim, :submitted, policy: Policies::StudentLoans),
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments),
          create(:claim, :submitted, policy: Policies::LevellingUpPremiumPayments)
        ]
      end

      it "contains the correct headers" do
        expect(csv.headers).to eql(Claim::DataReportRequest::HEADERS)
      end

      it "contains the correct values" do
        claims.each_with_index do |claim, index|
          expect(csv[index]["Claim reference"]).to eql(claim.reference)
          expect(csv[index]["Teacher reference number"]).to eql(claim.eligibility.teacher_reference_number)
          expect(csv[index]["NINO"]).to eql(claim.national_insurance_number)
          expect(csv[index]["Full name"]).to eql(claim.full_name)
          expect(csv[index]["Email"]).to eql(claim.email_address)
          expect(csv[index]["Date of birth"]).to eql(claim.date_of_birth.to_s)
          expect(csv[index]["ITT subject"]).to eql(claim.eligibility.eligible_itt_subject)
          expect(csv[index]["Policy name"]).to eql(claim.policy.to_s)
          expect(csv[index]["School name"]).to eql(claim.eligibility.current_school.name)
          expect(csv[index]["School unique reference number"]).to eql(claim.eligibility.current_school.urn.to_s)
        end
      end
    end

    context "FE policy claims" do
      let(:claims) do
        [
          create(:claim, :submitted, policy: Policies::FurtherEducationPayments)
        ]
      end

      it "contains the correct headers" do
        expect(csv.headers).to eql(Claim::DataReportRequest::HEADERS)
      end

      it "contains the correct values" do
        claims.each_with_index do |claim, index|
          expect(csv[index]["Claim reference"]).to eql(claim.reference)
          expect(csv[index]["Teacher reference number"]).to eql(claim.eligibility.teacher_reference_number)
          expect(csv[index]["NINO"]).to eql(claim.national_insurance_number)
          expect(csv[index]["Full name"]).to eql(claim.full_name)
          expect(csv[index]["Email"]).to eql(claim.email_address)
          expect(csv[index]["Date of birth"]).to eql(claim.date_of_birth.to_s)
          expect(csv[index]["ITT subject"]).to be_nil
          expect(csv[index]["Policy name"]).to eql(claim.policy.to_s)
          expect(csv[index]["School name"]).to eql(claim.eligibility.current_school.name)
          expect(csv[index]["School unique reference number"]).to eql(claim.eligibility.current_school.urn.to_s)
        end
      end
    end

    context "IRP policy claims" do
      let(:claims) do
        [
          create(:claim, :submitted, policy: Policies::InternationalRelocationPayments)
        ]
      end

      it "contains the correct headers" do
        expect(csv.headers).to eql(Claim::DataReportRequest::HEADERS)
      end

      it "contains the correct values" do
        claims.each_with_index do |claim, index|
          expect(csv[index]["Claim reference"]).to eql(claim.reference)
          expect(csv[index]["Teacher reference number"]).to eql(claim.eligibility.teacher_reference_number)
          expect(csv[index]["NINO"]).to eql(claim.national_insurance_number)
          expect(csv[index]["Full name"]).to eql(claim.full_name)
          expect(csv[index]["Email"]).to eql(claim.email_address)
          expect(csv[index]["Date of birth"]).to eql(claim.date_of_birth.to_s)
          expect(csv[index]["ITT subject"]).to be_nil
          expect(csv[index]["Policy name"]).to eql(claim.policy.to_s)
          expect(csv[index]["School name"]).to eql(claim.eligibility.current_school.name)
          expect(csv[index]["Payroll gender"]).to eql(claim.payroll_gender)
          expect(csv[index]["Nationality"]).to eql(claim.eligibility.nationality)
          expect(csv[index]["Passport number"]).to eql(claim.eligibility.passport_number)
        end
      end
    end

    context "EY policy claims" do
      let(:claims) do
        [
          create(:claim, :submitted, policy: Policies::EarlyYearsPayments)
        ]
      end

      it "contains the correct headers" do
        expect(csv.headers).to eql(Claim::DataReportRequest::HEADERS)
      end

      it "contains the correct values" do
        claims.each_with_index do |claim, index|
          expect(csv[index]["Claim reference"]).to eql(claim.reference)
          expect(csv[index]["Teacher reference number"]).to be_nil
          expect(csv[index]["NINO"]).to eql(claim.national_insurance_number)
          expect(csv[index]["Full name"]).to eql(claim.full_name)
          expect(csv[index]["Email"]).to eql(claim.email_address)
          expect(csv[index]["Date of birth"]).to eql(claim.date_of_birth.to_s)
          expect(csv[index]["ITT subject"]).to be_nil
          expect(csv[index]["Policy name"]).to eql(claim.policy.to_s)
          expect(csv[index]["School name"]).to eql(claim.eligibility.eligible_ey_provider.nursery_name)
          expect(csv[index]["School unique reference number"]).to eql(claim.eligibility.eligible_ey_provider.urn)
          expect(csv[index]["Payroll gender"]).to eql(claim.payroll_gender)
          expect(csv[index]["Nationality"]).to be_nil
          expect(csv[index]["Passport number"]).to be_nil
        end
      end
    end

    context "when there is a single quotation sign in name field" do
      let(:claims) do
        [
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Hara"),
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Hara", surname: "Brooks"),
          create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Brian", surname: "O'Hara")
        ]
      end

      it "contains the correct headers" do
        expect(csv.headers).to eql(Claim::DataReportRequest::HEADERS)
      end

      it "contains the correct values" do
        claims.each_with_index do |claim, index|
          expect(csv[index]["Claim reference"]).to eql(claim.reference)
          expect(csv[index]["Teacher reference number"]).to eql(claim.eligibility.teacher_reference_number)
          expect(csv[index]["NINO"]).to eql(claim.national_insurance_number)
          expect(csv[index]["Full name"]).to eql(claim.full_name)
          expect(csv[index]["Email"]).to eql(claim.email_address)
          expect(csv[index]["Date of birth"]).to eql(claim.date_of_birth.to_s)
          expect(csv[index]["ITT subject"]).to eql(claim.eligibility.eligible_itt_subject)
          expect(csv[index]["Policy name"]).to eql(claim.policy.to_s)
          expect(csv[index]["School name"]).to eql(claim.eligibility.current_school.name)
          expect(csv[index]["School unique reference number"]).to eql(claim.eligibility.current_school.urn.to_s)
        end
      end
    end
  end
end
