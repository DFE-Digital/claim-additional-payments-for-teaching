require "rails_helper"

RSpec.describe MathsAndPhysics::DqtRecord do
  maths_jac_codes = %w[G100 G290 G310 G320 G900]
  physics_jac_codes = %w[F300 F310 F320 F321 F331]
  example_eligible_jac_codes = maths_jac_codes + physics_jac_codes
  example_non_eligible_jac_codes = %w[X100 L800 F100 C700 R100]

  eligible_maths_hecos_codes = %w[100400 100401 100402 100403 100404 100405 100406 101027 101028 101029 101030 101031 101032 101033 101034].freeze
  eligible_physics_hecos_codes = %w[100416 100419 100425 100426 101060 101061 101068 101071 101074 101075 101076 101077 101223 101300 101390 101391].freeze
  example_eligible_hecos_codes = eligible_maths_hecos_codes + eligible_physics_hecos_codes
  example_non_eligible_hecos_codes = %w[100430 101066 101078 100300 100396 100427].freeze

  describe "#eligible?" do
    example_eligible_jac_codes.each do |jac_code|
      context "when the given ITT subject (#{jac_code}) is eligible" do
        let(:attributes) { {itt_subject_codes: [jac_code], degree_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      context "when the given degree (#{jac_code}) is eligible" do
        let(:attributes) { {degree_codes: [jac_code], itt_subject_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      it "returns false when given a record with a blank qts_date" do
        expect(MathsAndPhysics::DqtRecord.new({qts_date: "", itt_subject_codes: [jac_code], degree_codes: []}).eligible?).to eql false
      end
    end

    example_eligible_hecos_codes.each do |hecos_code|
      context "when the given ITT subject HECoS code (#{hecos_code}) is eligible" do
        let(:attributes) { {itt_subject_codes: [hecos_code], degree_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("1/10/2018")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      context "when the given degree (#{hecos_code}) is eligible" do
        let(:attributes) { {degree_codes: [hecos_code], itt_subject_codes: []} }

        it "returns true if the given QTS award date is after the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql true
        end

        it "returns true if the given QTS award date is in the first eligible academic year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("1/10/2015")})).eligible?).to eql true
        end

        it "returns false if the given date is not an eligible year" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("8/3/2000")})).eligible?).to eql false
        end
      end

      it "returns false when given a record with a blank qts_date" do
        expect(MathsAndPhysics::DqtRecord.new({qts_date: "", itt_subject_codes: [hecos_code], degree_codes: []}).eligible?).to eql false
      end
    end

    example_non_eligible_jac_codes.each do |jac_code|
      context "when the given ITT subject or degree (#{jac_code}) isn't eligible" do
        let(:attributes) { {itt_subject_codes: [jac_code], degree_codes: [jac_code]} }

        it "always returns false" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("19/3/2017")})).eligible?).to eql false
        end
      end
    end

    example_non_eligible_hecos_codes.each do |hecos_code|
      context "when given ITT subject or degree (#{hecos_code}) - HECOS code isn't eligible" do
        let(:attributes) { {itt_subject_codes: [hecos_code], degree_codes: [hecos_code]} }
        it "always returns false" do
          expect(MathsAndPhysics::DqtRecord.new(attributes.merge({qts_date: Date.parse("20/07/2017")})).eligible?).to eql false
        end
      end
    end
  end
end
