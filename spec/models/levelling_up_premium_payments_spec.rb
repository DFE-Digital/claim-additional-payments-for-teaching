require "rails_helper"

RSpec.describe Policies::LevellingUpPremiumPayments, type: :model do
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
      locale_key: "levelling_up_premium_payments",
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
end
