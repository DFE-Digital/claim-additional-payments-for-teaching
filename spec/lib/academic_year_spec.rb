require "rails_helper"
require "academic_year"

RSpec.describe AcademicYear do
  describe ".current" do
    it "returns the current academic year (based on September 1st being the start of the year)" do
      travel_to Date.new(2018, 8, 31) do
        expect(AcademicYear.current).to eq AcademicYear.new(2017)
      end
      travel_to Date.new(2018, 9, 1) do
        expect(AcademicYear.current).to eq AcademicYear.new(2018)
      end
      travel_to Date.new(2020, 9, 1) do
        expect(AcademicYear.current).to eq AcademicYear.new(2020)
      end
    end
  end

  it "can be initialised with the full academic year as a String" do
    expect(AcademicYear.new("2014/2015").start_year).to eq 2014
  end

  it "can be initialised with a single Integer year" do
    expect(AcademicYear.new(2020).start_year).to eq 2020
  end

  it "can be initialised with a single String year" do
    expect(AcademicYear.new("2019").start_year).to eq 2019
  end

  it "is comparable" do
    expect(AcademicYear.new(2012)).to eq AcademicYear.new(2012)
    expect(AcademicYear.new(2012)).not_to eq AcademicYear.new(2011)
  end

  it "supports arithmetic 'minus' with integers" do
    expect(AcademicYear.new(2012) - 1).to eq(AcademicYear.new(2011))
    expect(AcademicYear.new(2012) - 3).to eq(AcademicYear.new(2009))
  end

  it "supports arithmetic 'plus' with integers" do
    expect(AcademicYear.new(2022) + 1).to eq(AcademicYear.new(2023))
    expect(AcademicYear.new(2008) + 3).to eq(AcademicYear.new(2011))
  end

  describe "#to_s" do
    it "returns the accepted short format for displaying academic years" do
      expect(AcademicYear.new(2014).to_s).to eq "2014/2015"
      expect(AcademicYear.new("2020").to_s).to eq "2020/2021"
      expect(AcademicYear.new("2020/2021").to_s).to eq "2020/2021"
    end

    it "can return the long-form, more human-friendly version of the academic year" do
      expect(AcademicYear.new(2014).to_s(:long)).to eq "2014 to 2015"
      expect(AcademicYear.new("2020").to_s(:long)).to eq "2020 to 2021"
      expect(AcademicYear.new("2020/2021").to_s(:long)).to eq "2020 to 2021"
    end
  end
end
