require "rails_helper"

RSpec.describe ClaimDecision, type: :model do
  subject { ClaimDecision }

  let!(:claims) do
    [StudentLoans, EarlyCareerPayments, MathsAndPhysics, LevellingUpPremiumPayments].collect do |policy|
      create(:claim, :approved, policy: policy)
    end
  end

  let(:header) { subject.attribute_names }

  # rows have to be handled differently for each eligibility table as
  # subject and school vary between each. This mirrors the output of
  # the SQL view backing app/models/claim_decision.rb
  let(:rows) do
    ecp_claims = Claim.by_policy(EarlyCareerPayments).collect do |c|
      [
        c.id,
        c.latest_decision.created_at,
        c.teacher_reference_number,
        c.latest_decision.result,
        c.policy.to_s.underscore.tr("_", " "),
        c.eligibility.eligible_itt_subject.gsub("ematic", ""),
        c.eligibility.current_school.name,
        c.eligibility.current_school.local_authority.name,
        c.eligibility.current_school.local_authority_district.name,
        Time.zone.now.year - c.date_of_birth.year,
        c.payroll_gender,
        c.academic_year.to_s
      ]
    end
    maths_claims = Claim.by_policy(MathsAndPhysics).collect do |c|
      [
        c.id,
        c.latest_decision.created_at,
        c.teacher_reference_number,
        c.latest_decision.result,
        c.policy.to_s.underscore.tr("_", " "),
        c.eligibility.initial_teacher_training_subject,
        c.eligibility.current_school.name,
        c.eligibility.current_school.local_authority.name,
        c.eligibility.current_school.local_authority_district.name,
        Time.zone.now.year - c.date_of_birth.year,
        c.payroll_gender,
        c.academic_year.to_s
      ]
    end
    student_loan_claims = Claim.by_policy(StudentLoans).collect do |c|
      [
        c.id,
        c.latest_decision.created_at,
        c.teacher_reference_number,
        c.latest_decision.result,
        c.policy.to_s.underscore.tr("_", " "),
        c.eligibility.subjects_taught.first.to_s.gsub("_taught", ""),
        c.eligibility.claim_school.name,
        c.eligibility.claim_school.local_authority.name,
        c.eligibility.claim_school.local_authority_district.name,
        Time.zone.now.year - c.date_of_birth.year,
        c.payroll_gender,
        c.academic_year.to_s
      ]
    end

    ecp_claims + maths_claims + student_loan_claims
  end

  let(:expected_csv) do
    CSV.generate(headers: true) do |csv|
      csv << header

      rows.each do |row|
        csv << row
      end
    end
  end

  describe ".to_csv" do
    it "returns all expected rows as a csv" do
      given = subject.order(:application_policy).to_csv
      expect(given).to eq(expected_csv)
    end
  end
end
