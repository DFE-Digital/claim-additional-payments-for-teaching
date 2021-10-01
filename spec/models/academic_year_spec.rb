require "rails_helper"

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

  describe ".for" do
    it "returns the academic year for a given date (based on September 1st being the start of the year)" do
      expect(AcademicYear.for(Date.new(2018, 1, 1))).to eq AcademicYear.new(2017)
      expect(AcademicYear.for(Date.new(2018, 10, 1))).to eq AcademicYear.new(2018)
    end

    it "returns nil when given date is nil" do
      expect(AcademicYear.for(nil)).to equal nil
    end
  end

  describe AcademicYear::Type do
    describe "#serialize" do
      subject(:serialize) { described_class.new.serialize(arg) }

      context "with AcademicYear 2018" do
        let(:arg) { AcademicYear.new(2018) }

        it "returns 2018/2019" do
          expect(serialize).to eq "2018/2019"
        end
      end

      context "with AcademicYear nil" do
        let(:arg) { AcademicYear.new }

        it "returns None" do
          expect(serialize).to eq "None"
        end
      end

      context "with nil" do
        let(:arg) { nil }

        it "returns nil" do
          expect(serialize).to be nil
        end
      end
    end

    describe "#cast" do
      subject(:cast) { described_class.new.cast(arg) }

      context "with 2018/2019" do
        let(:arg) { "2018/2019" }

        it "returns AcademicYear 2018" do
          expect(cast).to eq AcademicYear.new(2018)
        end
      end

      context "with None" do
        let(:arg) { "None" }

        it "returns AcademicYear nil" do
          expect(cast).to eq AcademicYear.new
        end
      end

      context "with nil" do
        let(:arg) { nil }

        it "returns nil" do
          expect(cast).to be nil
        end
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

  describe "#==" do
    subject(:eq) { described_class.new(2018).==(arg) }

    context "with eq" do
      let(:arg) { described_class.new(2018) }

      it "returns true" do
        expect(eq).to be true
      end
    end

    context "with not eq" do
      let(:arg) { described_class.new }

      it "returns false" do
        expect(eq).to be false
      end
    end
  end

  describe "#eql?" do
    subject(:eql?) { AcademicYear.new(2018).eql?(other_academic_year) }

    context "when eql" do
      let(:other_academic_year) { AcademicYear.new(2018) }

      it "returns true" do
        expect(eql?).to be true
      end
    end

    context "when not eql" do
      let(:other_academic_year) { AcademicYear.new(2019) }

      it "returns false" do
        expect(eql?).to be false
      end
    end
  end

  describe "#to_s" do
    it "returns the accepted short format for displaying academic years" do
      expect(AcademicYear.new.to_s).to eq "None"
      expect(AcademicYear.new(2014).to_s).to eq "2014/2015"
      expect(AcademicYear.new("2020").to_s).to eq "2020/2021"
      expect(AcademicYear.new("2020/2021").to_s).to eq "2020/2021"
    end

    it "can return the long-form, more human-friendly version of the academic year" do
      expect(AcademicYear.new.to_s(:long)).to eq "None"
      expect(AcademicYear.new(2014).to_s(:long)).to eq "2014 to 2015"
      expect(AcademicYear.new("2020").to_s(:long)).to eq "2020 to 2021"
      expect(AcademicYear.new("2020/2021").to_s(:long)).to eq "2020 to 2021"
    end
  end

  describe "#hash" do
    it "returns the same Integer value for matching AcademicYears" do
      expect(AcademicYear.new(2014).hash).to be_a(Integer)

      expect(AcademicYear.new(2014).hash).to eql AcademicYear.new(2014).hash
      expect(AcademicYear.new("2020").hash).to eql AcademicYear.new(2020).hash

      expect(AcademicYear.new(2014).hash).not_to eql AcademicYear.new(2020).hash
      expect(AcademicYear.new(2014).hash).not_to eql 2014.hash
    end
  end
end
