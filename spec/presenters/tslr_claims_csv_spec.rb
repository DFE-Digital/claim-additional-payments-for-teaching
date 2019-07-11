require "rails_helper"

RSpec.describe TslrClaimsCsv do
  before do
    create(:tslr_claim, :submittable,
      reference: "B2W4L0KC",
      submitted_at: Time.zone.parse("2019-01-01 17:30:00"),
      qts_award_year: "2013-2014",
      current_school: create(:school, name: "Penistone Grammar School"),
      employment_status: :claim_school,
      full_name: "Bruce Wayne",
      address_line_1: "Stately Wayne Manor",
      address_line_3: "Gotham",
      postcode: "BAT123",
      date_of_birth: Date.parse("1939-01-01"),
      teacher_reference_number: "1234567",
      national_insurance_number: "QQ123456C",
      email_address: "batman@bat.com",
      mostly_teaching_eligible_subjects: true,
      bank_sort_code: "440026",
      bank_account_number: "70872490",
      student_loan_repayment_amount: "1500.00")
  end

  subject { described_class.new(claims) }
  let(:claims) { TslrClaim.all.order(:submitted_at) }

  describe "file" do
    let(:file) { subject.file }
    let(:csv) { CSV.read(file) }

    it "returns the correct headers" do
      expect(csv[0]).to eq([
        "Reference",
        "Submitted at",
        "Award Year",
        "Claim School",
        "Employment Status",
        "Current School",
        "Applicant Name",
        "Address 1",
        "Address 2",
        "Address 3",
        "Address 4",
        "Postcode",
        "Date of Birth",
        "Teacher Reference",
        "NI Number",
        "Email",
        "Mostly Teaching Eligible Subjects?",
        "Sort Code",
        "Account Number",
        "Repayment Amount",
      ])
    end

    it "returns the correct rows" do
      expect(csv[1]).to eq([
        "B2W4L0KC",
        "01/01/2019 17:30",
        "2013-2014",
        "Penistone Grammar School",
        "Claim school",
        "Penistone Grammar School",
        "Bruce Wayne",
        "Stately Wayne Manor",
        nil,
        "Gotham",
        nil,
        "BAT123",
        "01/01/1939",
        "1234567",
        "QQ123456C",
        "batman@bat.com",
        "Yes",
        "440026",
        "70872490",
        "£1500.0",
      ])
    end
  end
end
