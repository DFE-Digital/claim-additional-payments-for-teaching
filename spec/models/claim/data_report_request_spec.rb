require "rails_helper"
require "csv"

RSpec.describe Claim::DataReportRequest do
  describe "#to_csv" do
    let(:claims) { create_list :claim, 3, :submitted }
    let(:report_request) { described_class.new(claims) }

    subject(:report_request_csv) { CSV.parse(report_request.to_csv, headers: true) }

    it "contains the correct headers" do
      expect(report_request_csv.headers).to eql(Claim::DataReportRequest::HEADERS)
    end

    it "includes the claims reference number and teacher reference number" do
      expect(report_request_csv[2].fields("Claim reference")).to include(claims.last.reference)
      expect(report_request_csv[2].fields("Teacher reference number")).to include(claims.last.teacher_reference_number)
      expect(report_request_csv[2].fields("Full name")).to include(claims.last.full_name)
    end
    it "includes the claims email address and date of birth" do
      expect(report_request_csv[2].fields("Email")).to include(claims.last.email_address)
      expect(report_request_csv[2].fields("Date of birth")).to include(claims.last.date_of_birth.to_s)
    end
  end
end
