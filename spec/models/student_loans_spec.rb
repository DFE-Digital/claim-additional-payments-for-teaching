require "rails_helper"

RSpec.describe StudentLoans, type: :model do
  let(:policy_configuration) { policy_configurations(:student_loans) }

  describe ".first_eligible_qts_award_year" do
    it "returns 11 years prior to the currently configured academic year, with a floor of the 2013/2014 academic year" do
      policy_configuration.update!(current_academic_year: "2031/2032")
      expect(StudentLoans.first_eligible_qts_award_year).to eq AcademicYear.new(2020)

      policy_configuration.update!(current_academic_year: "2027/2028")
      expect(StudentLoans.first_eligible_qts_award_year).to eq AcademicYear.new(2016)

      policy_configuration.update!(current_academic_year: "2024/2025")
      expect(StudentLoans.first_eligible_qts_award_year).to eq AcademicYear.new(2013)

      policy_configuration.update!(current_academic_year: "2023/2024")
      expect(StudentLoans.first_eligible_qts_award_year).to eq AcademicYear.new(2013)
    end

    it "can return the AcademicYear based on a passed-in academic year" do
      expect(StudentLoans.first_eligible_qts_award_year(AcademicYear.new(2030))).to eq AcademicYear.new(2019)
    end
  end

  describe ".current_financial_year" do
    it "returns a human-friendly string for the financial year the policy is currently accepting claims for" do
      # Based on the current academic year set by the policy_configurations.yml fixtures
      expect(StudentLoans.current_financial_year).to eq "6 April 2024 and 5 April 2025"

      policy_configuration.update!(current_academic_year: "2020/2021")
      expect(StudentLoans.current_financial_year).to eq "6 April 2019 and 5 April 2020"
    end
  end
end
