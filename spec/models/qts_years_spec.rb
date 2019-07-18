# frozen_string_literal: true

require "rails_helper"

RSpec.describe QtsYears do
  describe ".first_eligible_year" do
    it "returns the first year of the eligible QTS years" do
      stub_const("QtsYears::ELIGIBLE_YEARS", ["2018-2019", "2019-2020"])
      expect(QtsYears.first_eligible_year).to eq "2018"
    end
  end

  describe ".option_values" do
    it "returns an array with all the allowable options for QTS year" do
      stub_const("QtsYears::ELIGIBLE_YEARS", ["2018-2019", "2019-2020"])
      expect(QtsYears.option_values).to eq ["before_2018", "2018-2019", "2019-2020"]
    end
  end

  describe ".eligible?" do
    subject { QtsYears.eligible?(years) }

    context "the given value is an eligible year" do
      let(:years) { "2015-2016" }
      it { is_expected.to be true }
    end

    context "the given value is NOT an eligible year" do
      let(:years) { "before_2013" }
      it { is_expected.to be false }
    end
  end
end
