require "rails_helper"

RSpec.describe MathsAndPhysics::DQTRecord do
  MATHS_JAC_CODES = %w[G100 G290 G310 G320 G900]
  PHYSICS_JAC_CODES = %w[F300 F310 F320 F321 F331]
  EXAMPLE_ELIGIBLE_JAC_CODES = MATHS_JAC_CODES + PHYSICS_JAC_CODES
  EXAMPLE_NON_ELIGIBLE_JAC_CODES = %w[X100 L800 F100 C700 R100]

  ELIGIBLE_MATHS_HECOS_CODES = %w[100400 100401 100402 100403 100404 100405 100406 101027 101028 101029 101030 101031 101032 101033 101034].freeze
  ELIGIBLE_PHYSICS_HECOS_CODES = %w[100416 100419 100425 100426 101060 101061 101068 101071 101074 101075 101076 101077 101223 101300 101390 101391].freeze
  EXAMPLE_ELIGIBLE_HECOS_CODES = ELIGIBLE_MATHS_HECOS_CODES + ELIGIBLE_PHYSICS_HECOS_CODES
  EXAMPLE_NON_ELIGIBLE_HECOS_CODES = %w[100430 101066 101078 100300 100396 100427].freeze

  describe "#eligible?" do
    EXAMPLE_ELIGIBLE_JAC_CODES.each do |jac_code|
      context "when the given ITT subject (#{jac_code}) is eligible" do
        let(:attributes) { {itt_subject_codes: [jac_code], degree_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      context "when the given degree (#{jac_code}) is eligible" do
        let(:attributes) { {degree_codes: [jac_code], itt_subject_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      it "returns false when given a record with a blank qts_date" do
        expect(MathsAndPhysics::DQTRecord.new({qts_date: "", itt_subject_codes: [jac_code], degree_codes: []}).eligible?).to eql false
      end
    end

    EXAMPLE_ELIGIBLE_HECOS_CODES.each do |hecos_code|
      context "when the given ITT subject HECoS code (#{hecos_code}) is eligible" do
        let(:attributes) { {itt_subject_codes: [hecos_code], degree_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("1/10/2018")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      context "when the given degree (#{hecos_code}) is eligible" do
        let(:attributes) { {degree_codes: [hecos_code], itt_subject_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      it "returns false when given a record with a blank qts_date" do
        expect(MathsAndPhysics::DQTRecord.new({qts_date: "", itt_subject_codes: [hecos_code], degree_codes: []}).eligible?).to eql false
      end
    end

    EXAMPLE_NON_ELIGIBLE_JAC_CODES.each do |jac_code|
      context "when the given ITT subject or degree (#{jac_code}) isn't eligible" do
        let(:attributes) { {itt_subject_codes: [jac_code], degree_codes: [jac_code]} }

        it "always returns false" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql false
        end
      end
    end

    EXAMPLE_NON_ELIGIBLE_HECOS_CODES.each do |hecos_code|
      context "when given ITT subject or degree (#{hecos_code}) - HECOS code isn't eligible" do
        let(:attributes) { {itt_subject_codes: [hecos_code], degree_codes: [hecos_code]} }
        it "always returns false" do
          expect(MathsAndPhysics::DQTRecord.new(attributes.merge({qts_date: Date.parse("20/07/2017")})).eligible?).to eql false
        end
      end
    end
  end
end
