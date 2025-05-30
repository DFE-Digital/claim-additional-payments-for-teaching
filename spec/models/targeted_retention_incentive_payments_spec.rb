require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments, type: :model do
  it { is_expected.to include(BasePolicy) }

  it do
    expect(subject::VERIFIERS).to eq([
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
    ])
  end

  specify {
    expect(subject).to have_attributes(
      short_name: "School Targeted Retention Incentive",
      locale_key: "targeted_retention_incentive_payments",
      notify_reply_to_id: "03ece7eb-2a5b-461b-9c91-6630d0051aa6",
      eligibility_page_url: "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-school-teachers",
      eligibility_criteria_url: "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-school-teachers#eligibility-criteria",
      payment_and_deductions_info_url: "https://www.gov.uk/guidance/targeted-retention-incentive-payments-for-school-teachers#payments-and-deductions"
    )
  }

  describe ".payroll_file_name" do
    subject(:payroll_file_name) { described_class.payroll_file_name }
    it { is_expected.to eq("SchoolsLUP") }
  end

  describe ".selectable_itt_years_for_view" do
    context "2022/2023 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2022)) }

      it { is_expected.to eq([AcademicYear.new(2017), AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021)]) }
    end

    context "2023/2024 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2023)) }

      it { is_expected.to eq([AcademicYear.new(2018), AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022)]) }
    end

    context "2024/2025 claim year" do
      subject { described_class.selectable_itt_years_for_claim_year(AcademicYear.new(2024)) }

      it { is_expected.to eq([AcademicYear.new(2019), AcademicYear.new(2020), AcademicYear.new(2021), AcademicYear.new(2022), AcademicYear.new(2023)]) }
    end
  end
end
