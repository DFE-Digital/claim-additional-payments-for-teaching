require "rails_helper"

RSpec.describe Admin::PolicyConfigurationsHelper, type: :helper do
  describe "#options_for_academic_year" do
    it "returns the current and next academic year (based on September 1st being the start of the year)" do
      travel_to Date.new(2018, 8, 31) do
        expect(helper.options_for_academic_year).to eq [
          AcademicYear.new(2017),
          AcademicYear.new(2018),
          AcademicYear.new(2019),
          AcademicYear.new(2020)
        ]
      end
      travel_to Date.new(2018, 9, 1) do
        expect(helper.options_for_academic_year).to eq [
          AcademicYear.new(2018),
          AcademicYear.new(2019),
          AcademicYear.new(2020),
          AcademicYear.new(2021)
        ]
      end
      travel_to Date.new(2020, 9, 1) do
        expect(helper.options_for_academic_year).to eq [
          AcademicYear.new(2020),
          AcademicYear.new(2021),
          AcademicYear.new(2022),
          AcademicYear.new(2023)
        ]
      end
    end
  end
end
