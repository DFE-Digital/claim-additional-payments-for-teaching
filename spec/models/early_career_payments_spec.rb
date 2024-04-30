require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments, type: :model do
  it { is_expected.to include(BasePolicy) }

  it do
    expect(subject::VERIFIERS).to eq([
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::Induction,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan
    ])
  end

  specify {
    expect(subject).to have_attributes(
      short_name: "Early-Career Payments",
      locale_key: "early_career_payments",
      eligibility_page_url: "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools",
      eligibility_criteria_url: "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools#eligibility-criteria",
      student_loan_balance_url: "https://www.gov.uk/sign-in-to-manage-your-student-loan-balance",
      payment_and_deductions_info_url: "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools#paying-income-tax-and-national-insurance",
      notify_reply_to_id: "3f85a1f7-9400-4b48-9a31-eaa643d6b977"
    )
  }

  describe ".first_eligible_qts_award_year" do
    it "can return the AcademicYear based on a passed-in academic year" do
      expect(described_class.first_eligible_qts_award_year(AcademicYear.new(2024))).to eq AcademicYear.new(2021)
    end
  end
end
