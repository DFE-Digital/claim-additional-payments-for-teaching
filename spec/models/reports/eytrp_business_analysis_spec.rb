require "rails_helper"

RSpec.describe Reports::EytrpBusinessAnalysis do
  subject(:report) { described_class.new }

  let(:policy) { Policies::EarlyYearsTeachersFinancialIncentivePayments }
  let(:academic_year) { AcademicYear.new(2026) }
  let(:nursery) do
    create(
      :eligible_eytfi_provider,
      name: 'Springfield, "Little Oaks"',
      paye_references: ["123/ABC", "456/DEF"],
      registered_person_name: "Springfield Childcare"
    )
  end

  def create_claim(eligibility_attributes: {}, **attributes)
    create(
      :claim,
      policy: policy,
      academic_year: academic_year,
      submitted_at: Time.zone.now,
      eligibility_attributes: {eligible_eytfi_provider_urn: nursery.urn}.merge(eligibility_attributes),
      **attributes
    )
  end

  describe "#to_csv" do
    it "reports the task, HMRC, nursery and decision details for a submitted EYTRP claim" do
      create(
        :eligible_eytfi_provider,
        file_upload: nursery.file_upload,
        registered_person_name: nursery.registered_person_name,
        eligible: false
      )
      claim = create_claim(
        eligibility_attributes: {
          hmrc_response_status: 200,
          hmrc_response_body: {
            employments: [
              {employer: {name: "Springfield, Ltd", payeReference: "123/ABC"}},
              {employer: {name: "Little Oaks", payeReference: "456/DEF"}}
            ]
          }.to_json
        }
      )
      create(:task, :automated, name: "employment", claim: claim, data: {"check" => "paye_reference", "passed" => true})
      create(:task, name: "provider_claim_count", claim: claim)
      allow(claim).to receive(:approvable?).and_return(true)
      create(:decision, :approved, claim: claim)
      create(:task, name: "student_loan_plan", claim: claim)

      rows = CSV.parse(report.to_csv, headers: true)

      expect(rows.map(&:fields)).to eq([
        [
          "https://claim-additional-teaching-payment.service.gov.uk/admin/claims/#{claim.id}/tasks",
          claim.reference,
          claim.submitted_at.iso8601,
          "PASS",
          "PASS",
          "Unknown QTS",
          "AUTO PASS",
          "FOUND",
          "2",
          "paye_reference",
          "true",
          "N/A",
          "Springfield  Ltd;Little Oaks",
          "123/ABC;456/DEF",
          'Springfield  "Little Oaks"',
          "123/ABC;456/DEF",
          "springfield childcare",
          "TRUE",
          "PASSED",
          "APPROVED",
          "APPROVED"
        ]
      ])
    end

    it "includes only submitted EYTRP claims from 2026 in creation order" do
      newer_claim = create_claim(eligibility_attributes: {hmrc_response_status: 404})
      older_claim = create_claim(created_at: 1.day.ago)
      create_claim(submitted_at: nil)
      create_claim(academic_year: AcademicYear.new(2025))
      create(:claim, :submitted, academic_year: academic_year)

      rows = CSV.parse(report.to_csv, headers: true)

      expect(rows["Reference"]).to eq([older_claim.reference, newer_claim.reference])
      expect(rows["employment"]).to eq(["INCOMPLETE", "INCOMPLETE"])
      expect(rows["HMRC response"]).to eq(["ERROR", "NOT FOUND"])
      expect(rows["HMRC number of employments found"]).to eq(["0", "0"])
      expect(rows["provider_claim_count"]).to eq(["N/A", "N/A"])
      expect(rows["Student loan plan"]).to eq(["N/A", "N/A"])
      expect(rows["Decision"]).to eq(["UNDECIDED", "UNDECIDED"])
      expect(rows["QA decision"]).to eq(["UNDECIDED", "UNDECIDED"])
    end
  end
end
