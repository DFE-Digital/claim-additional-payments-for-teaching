require "rails_helper"

RSpec.describe ClaimDecision, type: :model do
  subject { ClaimDecision }

  let!(:claims) do
    [StudentLoans, EarlyCareerPayments, MathsAndPhysics].collect do |policy|
      create(:claim, :approved, policy: policy)
    end
  end

  let(:header) { subject.attribute_names.join(",") }

  # rows have to be handled differently for each eligibility table as
  # subject and school vary between each. This mirrors the output of
  # the SQL view backing app/models/claim_decision.rb
  let(:rows) do
    [
      Claim.by_policy(EarlyCareerPayments).collect do |c|
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
        ].join(",")
      end,

      Claim.by_policy(MathsAndPhysics).collect do |c|
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
        ].join(",")
      end,

      Claim.by_policy(StudentLoans).collect do |c|
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
        ].join(",")
      end
    ].flatten
  end

  describe ".to_csv" do
    it "returns all expected rows as a csv" do
      expected = [header, rows].flatten.join("\n") << "\n"
      given = subject.order(:application_policy).to_csv
      expect(given).to eq(expected)
    end
  end
end
