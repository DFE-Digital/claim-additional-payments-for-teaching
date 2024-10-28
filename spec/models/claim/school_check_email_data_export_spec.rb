require "rails_helper"
require "csv"

RSpec.describe Claim::SchoolCheckEmailDataExport do
  let(:submitted_student_loans_claim) do
    eligibility = create(:student_loans_eligibility, :eligible, biology_taught: true, chemistry_taught: true, computing_taught: false, languages_taught: false, physics_taught: true)
    create(:claim, :submitted, eligibility: eligibility, first_name: "John", middle_name: "Herbert", surname: "Adams")
  end
  let!(:submitted_claims) { [submitted_student_loans_claim] }
  let!(:excluded_claims) { create_list(:claim, 3, :submitted) }
  let!(:approved_claims) { create_list(:claim, 2, :approved) }
  let!(:rejected_claims) { create_list(:claim, 2, :rejected) }

  subject { described_class.new(excluded_claims.map(&:reference).join(",")) }

  describe "#csv_string" do
    let(:csv) { CSV.parse(subject.csv_string, headers: true) }

    it "returns a parseable CSV string with the expected headers" do
      expect(csv.headers).to eq(["Claim reference", "Policy", "Current school URN", "Current school name", "Claim school URN", "Claim school name", "Claimant name", "Subject"])
    end

    it "contains a row for each submitted, non-excluded claim" do
      expect(csv.map { |row| row["Claim reference"] }).to match_array(submitted_claims.map(&:reference))
    end

    it "includes claims’ reference, policy, current school URN, current school name, claim school URN, claim school name and claimant name excluding middle name" do
      row = csv.find { |row| row["Claim reference"] == submitted_student_loans_claim.reference }

      expect(row["Policy"]).to eq("StudentLoans")
      expect(row["Current school URN"]).to eq(submitted_student_loans_claim.eligibility.current_school.urn.to_s)
      expect(row["Current school name"]).to eq(submitted_student_loans_claim.eligibility.current_school.name)
      expect(row["Claim school URN"]).to eq(submitted_student_loans_claim.eligibility.claim_school.urn.to_s)
      expect(row["Claim school name"]).to eq(submitted_student_loans_claim.eligibility.claim_school.name)
      expect(row["Claimant name"]).to eq("John Adams")
    end

    it "includes the subjects taught for a Student Loans claim" do
      row = csv.find { |row| row["Claim reference"] == submitted_student_loans_claim.reference }

      expect(row["Subject"]).to eq("biology, chemistry and physics")
    end
  end
end
