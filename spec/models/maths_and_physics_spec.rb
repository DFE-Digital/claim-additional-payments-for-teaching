require "rails_helper"

RSpec.describe MathsAndPhysics, type: :model do
  describe ".first_eligible_qts_award_year" do
    let(:policy_configuration) { policy_configurations(:maths_and_physics) }

    it "returns an AcademicYear five years before the currently configured current_academic_year" do
      policy_configuration.update!(current_academic_year: "2019/2020")
      expect(MathsAndPhysics.first_eligible_qts_award_year).to eq AcademicYear.new(2014)

      policy_configuration.update!(current_academic_year: "2025/2026")
      expect(MathsAndPhysics.first_eligible_qts_award_year).to eq AcademicYear.new(2020)
    end

    it "can return the AcademicYear based on a passed-in academic year" do
      expect(MathsAndPhysics.first_eligible_qts_award_year(AcademicYear.new(2021))).to eq AcademicYear.new(2016)
    end
  end
end
