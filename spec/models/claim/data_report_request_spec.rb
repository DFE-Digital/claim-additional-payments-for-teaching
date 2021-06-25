require "rails_helper"
require "csv"

RSpec.describe Claim::DataReportRequest do
  describe "#to_csv" do
    let(:claims) do
      [
        create(:claim, :submitted, policy: StudentLoans),
        create(:claim, :submitted, policy: MathsAndPhysics),
        create(:claim, :submitted, policy: EarlyCareerPayments)
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
        expect(report_request_csv[index].fields("Teacher reference number")).to include(claim.teacher_reference_number)
        expect(report_request_csv[index].fields("Full name")).to include(claim.full_name)
        expect(report_request_csv[index].fields("Email")).to include(claim.email_address)
        expect(report_request_csv[index].fields("Date of birth")).to include(claim.date_of_birth.to_s)
        expect(report_request_csv[index].fields("ITT subject")).to include(claim.eligibility.eligible_itt_subject)
        expect(report_request_csv[index].fields("Policy name")).to include(claim.policy.to_s)
      end
    end
  end
end
