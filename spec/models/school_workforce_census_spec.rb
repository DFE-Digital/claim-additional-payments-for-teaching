require "rails_helper"

RSpec.describe SchoolWorkforceCensus do
  let(:census_entry) { create(:school_workforce_census, :early_career_payments_matched) }

  describe "subjects" do
    it "returns an array of subjects" do
      expect(census_entry.subjects).to eq(["Mathematics / Mathematical Development (Early Years)", "Statistics"])
    end
  end
end
