require "rails_helper"
require "csv"

RSpec.describe Claim::DatabaseOfQualifiedTeachersReportRequest do
  describe "#to_csv" do
    let(:claims) { create_list :claim, 3, :submitted }
    let(:report_request) { described_class.new(claims) }

    subject(:report_request_csv) { CSV.parse(report_request.to_csv, headers: true) }

    it "contains the correct headers" do
      expect(report_request_csv.headers).to eql(Claim::DatabaseOfQualifiedTeachersReportRequest::ATTRIBUTES.values)
    end

    it "includes the claims reference number and teacher reference number" do
      expect(report_request_csv[2].fields("Claim reference")).to include(claims.last.reference)
      expect(report_request_csv[2].fields("Teacher reference number")).to include(claims.last.teacher_reference_number)
    end
  end
end
