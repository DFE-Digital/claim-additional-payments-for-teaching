require "rails_helper"

RSpec.describe Policies::StudentLoans, type: :model do
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  it { is_expected.to include(BasePolicy) }

  it do
    expect(subject::VERIFIERS).to eq([
      AutomatedChecks::ClaimVerifiers::Identity,
      AutomatedChecks::ClaimVerifiers::Qualifications,
      AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught,
      AutomatedChecks::ClaimVerifiers::Employment,
      AutomatedChecks::ClaimVerifiers::StudentLoanAmount,
      AutomatedChecks::ClaimVerifiers::FraudRisk
    ])
  end

  specify {
    expect(subject).to have_attributes(
      short_name: "Student Loans",
      locale_key: "student_loans",
      notify_reply_to_id: "962b3044-cdd4-4dbe-b6ea-c461530b3dc6",
      eligibility_page_url: "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments",
      payment_and_deductions_info_url: "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments#payment"
    )
  }

  describe ".first_eligible_qts_award_year" do
    it "returns 11 years prior to the currently configured academic year, with a floor of the 2013/2014 academic year" do
      journey_configuration.update!(current_academic_year: "2031/2032")
      expect(described_class.first_eligible_qts_award_year).to eq AcademicYear.new(2019)

      journey_configuration.update!(current_academic_year: "2027/2028")
      expect(described_class.first_eligible_qts_award_year).to eq AcademicYear.new(2015)

      journey_configuration.update!(current_academic_year: "2024/2025")
      expect(described_class.first_eligible_qts_award_year).to eq AcademicYear.new(2013)

      journey_configuration.update!(current_academic_year: "2023/2024")
      expect(described_class.first_eligible_qts_award_year).to eq AcademicYear.new(2013)
    end

    it "can return the AcademicYear based on a passed-in academic year" do
      expect(described_class.first_eligible_qts_award_year(AcademicYear.new(2030))).to eq AcademicYear.new(2018)
    end
  end

  describe ".last_eligible_qts_award_year" do
    subject(:year) { described_class.last_eligible_qts_award_year }
    it { is_expected.to eq(AcademicYear.new(2020)) }
  end

  describe ".current_financial_year" do
    it "returns a human-friendly string for the financial year the policy is currently accepting claims for" do
      journey_configuration.update!(current_academic_year: "2020/2021")
      expect(described_class.current_financial_year).to eq "6 April 2019 and 5 April 2020"
    end
  end

  describe ".payroll_file_name" do
    subject(:payroll_file_name) { described_class.payroll_file_name }
    it { is_expected.to eq("TSLR") }
  end
end
