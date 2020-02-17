require "rails_helper"

RSpec.describe Admin::PolicyConfigurationsHelper, type: :helper do
  describe "#options_for_academic_year" do
    it "returns the current and next academic year (based on September 1st being the start of the year)" do
      travel_to Date.new(2018, 8, 31) do
        expect(helper.options_for_academic_year).to eq ["2017/2018", "2018/2019"]
      end
      travel_to Date.new(2018, 9, 1) do
        expect(helper.options_for_academic_year).to eq ["2018/2019", "2019/2020"]
      end
      travel_to Date.new(2020, 9, 1) do
        expect(helper.options_for_academic_year).to eq ["2020/2021", "2021/2022"]
      end
    end
  end
end
