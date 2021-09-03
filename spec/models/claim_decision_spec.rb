require "rails_helper"

RSpec.describe ClaimDecision, type: :model do
  subject { ClaimDecision }

  let!(:claims) do
    [StudentLoans, EarlyCareerPayments, MathsAndPhysics].collect do |policy|
      create(:claim, :approved, policy: policy)
    end
  end

  let(:header) { subject.attribute_names.join(",") }

  let(:rows) do
    Claim.all.order(:id).collect do |c|
      [
        c.id,
        c.latest_decision.created_at,
        c.teacher_reference_number,
        c.latest_decision.result,
        c.policy.to_s.underscore.tr("_", " "),
        c.eligibility.subject,
        c.school.name,
        c.school.local_authority.name,
        c.school.local_authority_district.name,
        Time.zone.now.year - c.date_of_birth.year,
        c.payroll_gender,
        c.academic_year.to_s
      ].join(",")
    end
  end

  describe ".to_csv" do
    it "returns all expected rows as a csv" do
      expected = [header, rows].flatten.join("\n") << "\n"
      given = subject.order(:application_id).to_csv
      expect(given).to eq(expected)
    end
  end
end
