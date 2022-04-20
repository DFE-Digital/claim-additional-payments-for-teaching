require "rails_helper"

RSpec.describe School, type: :model do
  it { should belong_to(:local_authority) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:urn) }
  it { should validate_presence_of(:school_type_group) }
  it { should validate_presence_of(:school_type) }
  it { should validate_presence_of(:phase) }

  describe ".search" do
    it "returns schools with a name matching the search term" do
      expect(School.search("Penistone")).to match_array([schools(:penistone_grammar_school)])
    end

    it "returns schools with a postcode matching the search term" do
      expect(School.search("NW2 3RT")).to match_array([schools(:hampstead_school)])
    end

    it "raises an ArgumentError when the search term has fewer than 3 characters" do
      expect { School.search("Pe") }.to raise_error(ArgumentError, School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR)
    end

    it "limits the results" do
      stub_const("School::SEARCH_RESULTS_LIMIT", 1)
      expect(School.search("School").count).to eql(1)
    end
  end

  describe "#address" do
    it "returns a formatted address string" do
      school = School.new(
        street: "10 The Street",
        locality: "The locality",
        town: "Town",
        county: "County",
        postcode: "PC1 4TE"
      )
      expect(school.address).to eql("10 The Street, The locality, Town, County, PC1 4TE")
    end

    it "returns a formatted address string when attributes are missing" do
      school = School.new(
        street: "10 The Street",
        locality: "",
        town: "Town",
        county: "County",
        postcode: "PC1 4TE"
      )
      expect(school.address).to eql("10 The Street, Town, County, PC1 4TE")
    end
  end

  describe "#dfe_number" do
    let(:school) do
      build(:school,
        name: "Bash Street School",
        urn: "1234",
        establishment_number: 4567,
        local_authority: build(:local_authority, code: 123))
    end

    it "returns a combination of local authority code and establishment number" do
      expect(school.dfe_number).to eq("123/4567")
    end
  end

  describe "#state_funded?" do
    it "returns true for state funded school type groups" do
      School::STATE_FUNDED_SCHOOL_TYPE_GROUPS.each do |group|
        expect(School.new(school_type_group: group).state_funded?).to eq true
      end
    end

    it "returns false for school type groups that are not state funded" do
      non_state_funded = School::SCHOOL_TYPE_GROUPS.keys.map(&:to_s) - School::STATE_FUNDED_SCHOOL_TYPE_GROUPS

      non_state_funded.each do |phase|
        expect(School.new(school_type_group: phase).state_funded?).to eq false
      end
    end

    it "returns true for City Technology Colleges" do
      expect(School.new(school_type: :city_technology_college, school_type_group: :independent_schools).state_funded?).to eq true
    end
  end

  describe "#secondary_or_equivalent?" do
    it "returns true for a secondary school" do
      School::SECONDARY_PHASES.each do |phase|
        expect(School.new(phase: phase).secondary_or_equivalent?).to eq true
      end
    end

    it "returns false for schools that are not secondary" do
      non_secondary_phases = School::PHASES.keys.map(&:to_s) - School::SECONDARY_PHASES

      non_secondary_phases.each do |phase|
        expect(School.new(phase: phase).secondary_or_equivalent?).to eq false
      end
    end

    it "returns true for a special school that teaches students over eleven" do
      school = School.new(school_type: :community_special_school, statutory_high_age: 16)
      expect(school.secondary_or_equivalent?).to eq true
    end

    it "returns false for a special school that teaches students eleven or under" do
      school = School.new(school_type: :community_special_school, statutory_high_age: 11)
      expect(school.secondary_or_equivalent?).to eq false
    end

    it "returns false for a non special school that teaches students over eleven" do
      school = School.new(school_type: :community_school, statutory_high_age: 16)
      expect(school.secondary_or_equivalent?).to eq false
    end

    it "returns false for a special school that is a post 16 institution" do
      school = School.new(school_type: :special_post_16_institutions, statutory_high_age: 18)
      expect(school.secondary_or_equivalent?).to eq false
    end

    it "returns true for a alternative provision school that teaches students over eleven" do
      school = School.new(school_type: :pupil_referral_unit, statutory_high_age: 16)
      expect(school.secondary_or_equivalent?).to eq true
    end

    it "returns false for a alternative provision school that teaches students under eleven" do
      school = School.new(school_type: :pupil_referral_unit, statutory_high_age: 11)
      expect(school.secondary_or_equivalent?).to eq false
    end

    it "returns false for a non alternative provision school that teaches students over 11" do
      school = School.new(school_type: :community_school, statutory_high_age: 16)
      expect(school.secondary_or_equivalent?).to eq false
    end

    it "returns true for a City Technology College that teaches students over eleven" do
      school = School.new(school_type: :city_technology_college, statutory_high_age: 16)
      expect(school.secondary_or_equivalent?).to eq true
    end

    it "returns false for a City Technology College that only teaches students under eleven" do
      school = School.new(school_type: :city_technology_college, statutory_high_age: 10)
      expect(school.secondary_or_equivalent?).to eq false
    end
  end

  describe "#eligible_for_early_career_payments_as_uplift?" do
    it "delegates to SchoolEligibility#eligible_uplift?" do
      class_double = class_double(EarlyCareerPayments::SchoolEligibility).as_stubbed_const
      instance_double = instance_double(EarlyCareerPayments::SchoolEligibility)
      allow(class_double).to receive(:new).and_return(instance_double)
      allow(instance_double).to receive(:eligible_uplift?)

      School.new.eligible_for_early_career_payments_as_uplift?

      expect(instance_double).to have_received(:eligible_uplift?)
    end
  end

  describe "#open?" do
    # Both of these are the same physical school, but are different entities with unique URN's
    # Oulder Hill Community School and Language College is proposed to close 2021-12-31
    # Oulder Hill Leadership Academy is proposed to open 2022-01-01
    let(:oulder_hill_school_closing_dec_2021) do
      School.find(ActiveRecord::FixtureSet.identify(:oulder_hill_community_school_and_language_college, :uuid))
    end

    let(:oulder_hill_academy_opening_jan_2022) do
      School.find(ActiveRecord::FixtureSet.identify(:oulder_hill_leadership_academy, :uuid))
    end

    context "with a close_date of 31-Dec-2021 that is today or in the past" do
      it "is false" do
        travel_to(Time.zone.local(2022, 9, 1)) do
          expect(oulder_hill_school_closing_dec_2021.open?).to be false
        end
      end
    end

    context "with a close_date of 31-Dec-2021 that is in the future" do
      it "is true" do
        travel_to Time.zone.local(2021, 9, 27) do
          expect(oulder_hill_school_closing_dec_2021.open?).to be true
        end
      end
    end

    context "with a close_date that is nil" do
      it "is true" do
        oulder_hill_school_closing_dec_2021.update(close_date: nil)

        travel_to Time.zone.local(2021, 9, 20) do
          expect(oulder_hill_school_closing_dec_2021.open?).to be true
        end
      end
    end

    context "with a open_date of 1-Jan-2022 in the future" do
      it "is false" do
        travel_to Time.zone.local(2021, 9, 27) do
          expect(oulder_hill_academy_opening_jan_2022.open?).to be false
        end
      end
    end

    context "with a open_date of 1-Jan-2022 in the future" do
      it "is true" do
        travel_to Time.zone.local(2022, 1, 1) do
          expect(oulder_hill_academy_opening_jan_2022.open?).to be true
        end
      end
    end
  end
end
