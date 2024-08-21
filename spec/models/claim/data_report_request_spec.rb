require "rails_helper"
require "csv"

RSpec.describe Claim::DataReportRequest do
  describe "#to_csv" do
    let(:claims) do
      [
        create(:claim, :submitted, policy: Policies::StudentLoans),
        create(:claim, :submitted, policy: Policies::EarlyCareerPayments),
        create(:claim, :submitted, policy: Policies::LevellingUpPremiumPayments),
        create(:claim, :submitted, policy: Policies::FurtherEducationPayments)
      ]
    end

    let(:report_request) { described_class.new(claims) }

    subject(:report_request_csv) { CSV.parse(report_request.to_csv, headers: true) }

    it "contains the correct headers" do
      expect(report_request_csv.headers).to eql(Claim::DataReportRequest::HEADERS)
    end

    it "contains the correct values" do
      claims.each_with_index do |claim, index|
        expect(report_request_csv[index].fields("Claim reference")).to include(claim.reference)
        expect(report_request_csv[index].fields("Teacher reference number")).to include(claim.eligibility.teacher_reference_number)
        expect(report_request_csv[index].fields("NINO")).to include(claim.national_insurance_number)
        expect(report_request_csv[index].fields("Full name")).to include(claim.full_name)
        expect(report_request_csv[index].fields("Email")).to include(claim.email_address)
        expect(report_request_csv[index].fields("Date of birth")).to include(claim.date_of_birth.to_s)
        expect(report_request_csv[index].fields("ITT subject")).to include(claim.eligibility.try(:eligible_itt_subject))
        expect(report_request_csv[index].fields("Policy name")).to include(claim.policy.to_s)
        expect(report_request_csv[index].fields("School name")).to include(claim.eligibility.current_school.name)
        expect(report_request_csv[index].fields("School unique reference number")).to include(claim.eligibility.current_school.urn.to_s)
      end
    end
  end

  context "when there is a single quatation sign in name field" do
    let(:claims) do
      [
        create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Hara"),
        create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Hara", surname: "Brooks"),
        create(:claim, :submitted, policy: Policies::EarlyCareerPayments, first_name: "Kevin", middle_name: "O'Brian", surname: "O'Hara")
      ]
    end

    let(:report_request) { described_class.new(claims) }

    subject(:report_request_csv) { CSV.parse(report_request.to_csv, headers: true) }

    it "contains the correct headers" do
      expect(report_request_csv.headers).to eql(Claim::DataReportRequest::HEADERS)
    end

    it "contains the correct values" do
      claims.each_with_index do |claim, index|
        expect(report_request_csv[index].fields("Claim reference")).to include(claim.reference)
        expect(report_request_csv[index].fields("Teacher reference number")).to include(claim.eligibility.teacher_reference_number)
        expect(report_request_csv[index].fields("NINO")).to include(claim.national_insurance_number)
        expect(report_request_csv[index].fields("Full name")).to include(claim.full_name)
        expect(report_request_csv[index].fields("Email")).to include(claim.email_address)
        expect(report_request_csv[index].fields("Date of birth")).to include(claim.date_of_birth.to_s)
        expect(report_request_csv[index].fields("ITT subject")).to include(claim.eligibility.eligible_itt_subject)
        expect(report_request_csv[index].fields("Policy name")).to include(claim.policy.to_s)
        expect(report_request_csv[index].fields("School name")).to include(claim.eligibility.current_school.name)
        expect(report_request_csv[index].fields("School unique reference number")).to include(claim.eligibility.current_school.urn.to_s)
      end
    end
  end
end
