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
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::FraudRisk
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

  describe ".payroll_file_name" do
    subject(:payroll_file_name) { described_class.payroll_file_name }
    it { is_expected.to eq("EarlyCareerPayments") }
  end

  describe ".current_and_future_subject_symbols" do
    subject(:current_and_future_subject_symbols) do
      described_class.current_and_future_subject_symbols(
        claim_year: claim_year,
        itt_year: itt_year
      )
    end

    context "2022 claim year" do
      let(:claim_year) { AcademicYear.new(2022) }

      context "None of the above ITT year" do
        let(:itt_year) { AcademicYear.new }

        it { is_expected.to be_empty }
      end

      context "2017 ITT year" do
        let(:itt_year) { AcademicYear.new(2017) }

        it { is_expected.to be_empty }
      end

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear.new(2018) }

        it { is_expected.to contain_exactly(:mathematics) }
      end

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        it { is_expected.to contain_exactly(:mathematics) }
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
      end
    end

    context "2023 claim year" do
      let(:claim_year) { AcademicYear.new(2023) }

      context "2018 ITT year" do
        let(:itt_year) { AcademicYear.new(2018) }

        it { is_expected.to contain_exactly(:mathematics) }
      end

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        it { is_expected.to contain_exactly(:mathematics) }
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
      end

      context "2021 ITT year" do
        let(:itt_year) { AcademicYear.new(2021) }

        it { is_expected.to be_empty }
      end

      context "2022 ITT year" do
        let(:itt_year) { AcademicYear.new(2022) }

        it { is_expected.to be_empty }
      end
    end

    context "2024 claim year" do
      let(:claim_year) { AcademicYear.new(2024) }

      context "2019 ITT year" do
        let(:itt_year) { AcademicYear.new(2019) }

        it { is_expected.to contain_exactly(:mathematics) }
      end

      context "2020 ITT year" do
        let(:itt_year) { AcademicYear.new(2020) }

        it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
      end

      context "2021 ITT year" do
        let(:itt_year) { AcademicYear.new(2021) }

        it { is_expected.to be_empty }
      end

      context "2022 ITT year" do
        let(:itt_year) { AcademicYear.new(2022) }

        it { is_expected.to be_empty }
      end

      context "2023 ITT year" do
        let(:itt_year) { AcademicYear.new(2023) }

        it { is_expected.to be_empty }
      end
    end
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
