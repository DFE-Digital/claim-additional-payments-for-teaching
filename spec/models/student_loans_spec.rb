require "rails_helper"

RSpec.describe StudentLoans, type: :model do
  describe ".first_eligible_qts_award_year" do
    let(:policy_configuration) { policy_configurations(:student_loans) }

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
  end
end
