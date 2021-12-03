require "rails_helper"

RSpec.describe EarlyCareerPayments::SchoolEligibility do
  describe "#eligible_current_school?" do
    context "with a secondary school" do
      let(:secondary_school) {
        School.new(
          school_type_group: :la_maintained,
          phase: :secondary,
          close_date: nil,
          local_authority_district: local_authority_districts(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary school in an eligible local authority district" do
        expect(EarlyCareerPayments::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        secondary_school.assign_attributes(close_date: Date.new)
        expect(EarlyCareerPayments::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql false
      end

      it "returns false when not state funded" do
        secondary_school.assign_attributes(school_type_group: :independent_schools)
        expect(EarlyCareerPayments::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql false
      end
    end

    context "with an explicitly eligible school in an ineligible local authority district" do
      let(:explicitly_eligible_school) {
        School.new(
          school_type_group: :free_schools,
          phase: :secondary,
          close_date: nil,
          urn: 148577,
          local_authority_district: nil
        )
      }

      it "returns true if the school is otherwise eligible" do
        expect(EarlyCareerPayments::SchoolEligibility.new(explicitly_eligible_school).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        explicitly_eligible_school.assign_attributes(close_date: Date.new)
        expect(EarlyCareerPayments::SchoolEligibility.new(explicitly_eligible_school).eligible_current_school?).to eql false
      end

      it "returns false when not state funded" do
        explicitly_eligible_school.assign_attributes(school_type_group: :independent_schools)
        expect(EarlyCareerPayments::SchoolEligibility.new(explicitly_eligible_school).eligible_current_school?).to eql false
      end
    end

    context "with a special school" do
      let(:special_school) {
        School.new(
          close_date: nil,
          school_type: :community_special_school,
          school_type_group: :special_schools,
          statutory_high_age: 16,
          local_authority_district: local_authority_districts(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary equivalent special school in an eligible local authority district" do
        expect(EarlyCareerPayments::SchoolEligibility.new(special_school).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        special_school.assign_attributes(close_date: Date.new)
        expect(EarlyCareerPayments::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end

      it "returns false when not state funded" do
        special_school.assign_attributes(school_type_group: :independent_schools)
        expect(EarlyCareerPayments::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        special_school.assign_attributes(statutory_high_age: 11)
        expect(EarlyCareerPayments::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end
    end

    context "with alternative provision school" do
      let(:alternative_provision_school) {
        School.new(
          close_date: nil,
          school_type_group: :la_maintained,
          school_type: :pupil_referral_unit,
          statutory_high_age: 19,
          local_authority_district: local_authority_districts(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary equivalent alternative provision school in an eligible local authority district" do
        expect(EarlyCareerPayments::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end

      it "returns false when closed" do
        alternative_provision_school.assign_attributes(close_date: Date.new)
        expect(EarlyCareerPayments::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        alternative_provision_school.assign_attributes(statutory_high_age: 11)
        expect(EarlyCareerPayments::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq false
      end

      it "returns true with a secure unit" do
        alternative_provision_school.assign_attributes(school_type_group: :other, school_type: :secure_unit)
        expect(EarlyCareerPayments::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end
    end

    context "with a City Technology College (CTC)" do
      let(:city_technology_college) {
        School.new(
          close_date: nil,
          school_type: :city_technology_college,
          school_type_group: :independent_schools,
          statutory_high_age: 16,
          local_authority_district: local_authority_districts(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary equivalent CTC in an eligible local authority district" do
        expect(EarlyCareerPayments::SchoolEligibility.new(city_technology_college).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        city_technology_college.assign_attributes(close_date: Date.new)
        expect(EarlyCareerPayments::SchoolEligibility.new(city_technology_college).eligible_current_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        city_technology_college.assign_attributes(statutory_high_age: 11)
        expect(EarlyCareerPayments::SchoolEligibility.new(city_technology_college).eligible_current_school?).to eq false
      end
    end
  end

  context "when it is not a secondary school" do
    it "returns false" do
      primary_school = School.new(
        phase: :primary,
        school_type_group: :la_maintained,
        local_authority_district: local_authority_districts(:barnsley)
      )
      expect(EarlyCareerPayments::SchoolEligibility.new(primary_school).eligible_current_school?).to eql false
    end
  end

  describe "#eligible_uplift?" do
    it "returns false when not an 'eligible_current_school?'" do
      ineligible_school = School.new(
        close_date: Date.parse("2012-08-31"),
        school_type: :city_technology_college,
        school_type_group: :independent_schools,
        statutory_high_age: 16,
        local_authority_district: local_authority_districts(:camden)
      )

      expect(EarlyCareerPayments::SchoolEligibility.new(ineligible_school).eligible_uplift?).to eql false
    end

    it "returns false when the school is not in an uplifted local authority" do
      eligible_school_not_in_uplift_area = School.new(
        close_date: nil,
        school_type: :city_technology_college,
        school_type_group: :independent_schools,
        statutory_high_age: 16,
        local_authority_district: local_authority_districts(:camden)
      )

      expect(EarlyCareerPayments::SchoolEligibility.new(eligible_school_not_in_uplift_area).eligible_uplift?).to eql false
    end

    it "returns true when the school is in an uplifted local authority" do
      uplift_school = School.new(
        close_date: nil,
        school_type: :city_technology_college,
        school_type_group: :independent_schools,
        statutory_high_age: 16,
        local_authority_district: local_authority_districts(:barnsley)
      )

      expect(EarlyCareerPayments::SchoolEligibility.new(uplift_school).eligible_uplift?).to be true
    end

    context "when has a close date in the future" do
      it "returns true when the school is in an uplifted local authority" do
        travel_to(Date.new(2021, 9, 20)) do
          uplift_school = School.new(
            close_date: Date.new(2021, 12, 31),
            school_type: :city_technology_college,
            school_type_group: :independent_schools,
            statutory_high_age: 16,
            local_authority_district: local_authority_districts(:barnsley)
          )

          expect(EarlyCareerPayments::SchoolEligibility.new(uplift_school).eligible_uplift?).to be true
        end
      end
    end

    context "when has a close date in the past" do
      it "returns false when the school is in an uplifted local authority" do
        travel_to(Date.new(2022, 9, 1)) do
          uplift_school = School.new(
            close_date: Date.new(2021, 12, 31),
            school_type: :city_technology_college,
            school_type_group: :independent_schools,
            statutory_high_age: 16,
            local_authority_district: local_authority_districts(:barnsley)
          )

          expect(EarlyCareerPayments::SchoolEligibility.new(uplift_school).eligible_uplift?).to be false
        end
      end
    end
  end
end
