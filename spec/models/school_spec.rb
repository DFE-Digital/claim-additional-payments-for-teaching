require "rails_helper"

RSpec.describe School, type: :model do
  it { should belong_to(:local_authority) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:urn) }
  it { should validate_presence_of(:school_type_group) }
  it { should validate_presence_of(:school_type) }
  it { should validate_presence_of(:phase) }

  describe ".search" do
    let!(:first_school) { create(:school, name: "Community School London", postcode: "SW1P 3BT") }
    let!(:second_school) { create(:school, name: "Unity School London", postcode: "SW1P 3BT") }
    let!(:third_school) { create(:school, :further_education, name: "The Unity College Manchester", postcode: "M1 2WD") }

    it "returns schools with a name matching the search term" do
      expect(School.search("School")).to match_array([first_school, second_school])
    end

    it "returns schools with a postcode matching the search term" do
      expect(School.search("M1 2WD")).to match_array([third_school])
    end

    it "returns schools with a postcode that starts with the search term" do
      expect(School.search("SW1")).to match_array([first_school, second_school])
    end

    it "raises an ArgumentError when the search term has fewer than 3 characters" do
      expect { School.search("Pe") }.to raise_error(ArgumentError, School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR)
    end

    it "limits the results" do
      stub_const("School::SEARCH_RESULTS_LIMIT", 1)
      expect(School.search("School").count).to eql(1)
    end

    it "orders the results by similarity" do
      expect(School.search("Unity School")).to eq([second_school, first_school])
    end

    context "when searching for FE only" do
      it "only returns FE bodies" do
        expect(School.search("Unity", fe_only: true)).to eq([third_school])
      end
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
      class_double = class_double(Policies::EarlyCareerPayments::SchoolEligibility).as_stubbed_const
      instance_double = instance_double(Policies::EarlyCareerPayments::SchoolEligibility)
      allow(class_double).to receive(:new).and_return(instance_double)
      allow(instance_double).to receive(:eligible_uplift?)

      School.new.eligible_for_early_career_payments_as_uplift?

      expect(instance_double).to have_received(:eligible_uplift?)
    end
  end

  describe "#open?" do
    subject(:school) { build(:school, open_date: open_date, close_date: close_date) }

    context "when the school is closed or due to close" do
      let(:open_date) { 100.days.ago }

      context "with a close_date that is today or in the past" do
        let(:close_date) { 10.days.ago }

        it { is_expected.not_to be_open }
      end

      context "with a close_date that is in the future" do
        let(:close_date) { 10.days.from_now }

        it { is_expected.to be_open }
      end
    end

    context "when the school is not closed" do
      let(:close_date) { nil }

      context "with a close_date that is nil" do
        let(:open_date) { 100.days.ago }

        it { is_expected.to be_open }
      end

      context "with a open_date in the future" do
        let(:open_date) { 10.days.from_now }

        it { is_expected.not_to be_open }
      end

      context "with a open_date of today" do
        let(:open_date) { Date.today }

        it { is_expected.to be_open }
      end
    end
  end

  describe "#closed?" do
    context "closed school" do
      subject(:school) { build(:school, :closed) }

      it { is_expected.to be_closed }
    end

    context "open school" do
      subject(:school) { build(:school, :open) }

      it { is_expected.not_to be_closed }
    end
  end

  describe "#closed_before_date?" do
    subject(:school) { build(:school, open_date: open_date, close_date: close_date) }

    context "close_date earlier than date" do
      let(:open_date) { 100.days.ago }
      let(:close_date) { 10.days.ago }

      it { is_expected.to be_closed_before_date(Date.current) }
    end

    context "close_date after date" do
      let(:open_date) { 100.days.ago }
      let(:close_date) { 10.days.from_now }

      it { is_expected.not_to be_closed_before_date(Date.current) }
    end
  end

  describe "callbacks" do
    before { expect(school.postcode_sanitised).to be_nil }

    context "when the school has no postcode" do
      subject(:school) { build(:school, postcode: nil) }

      it "does not set postcode_sanitised" do
        school.save!
        expect(school.postcode_sanitised).to be_nil
      end
    end

    context "when the school has a postcode" do
      subject(:school) { build(:school, postcode: "AB12 3CD") }

      it "strips space characters and saves it to postcode_sanitised" do
        school.save!
        expect(school.postcode_sanitised).to eq("AB123CD")
      end
    end
  end

  describe "enum_methods" do
    context "when set by name" do
      it "sets the string column" do
        school = create(
          :school,
          phase: :secondary,
          school_type_group: :free_schools,
          school_type: :free_school
        )

        expect(school.phase_string).to eq("secondary")
        expect(school.school_type_group_string).to eq("free_schools")
        expect(school.school_type_string).to eq("free_school")
      end
    end

    context "when set by value" do
      it "sets the string column" do
        school = create(
          :school,
          phase: 4,
          school_type_group: 11,
          school_type: 35
        )

        expect(school.phase_string).to eq("secondary")
        expect(school.school_type_group_string).to eq("free_schools")
        expect(school.school_type_string).to eq("free_school")
      end
    end
  end
end
