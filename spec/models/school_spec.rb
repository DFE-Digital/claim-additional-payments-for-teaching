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

  describe ".phase_code_to_enum" do
    describe ".phase_code_to_enum" do
      it "returns the correct symbol for a valid phase code" do
        expect(School.phase_code_to_enum(0)).to eq(:not_applicable)
        expect(School.phase_code_to_enum(1)).to eq(:nursery)
        expect(School.phase_code_to_enum(2)).to eq(:primary)
        expect(School.phase_code_to_enum(3)).to eq(:middle_deemed_primary)
        expect(School.phase_code_to_enum(4)).to eq(:secondary)
        expect(School.phase_code_to_enum(5)).to eq(:middle_deemed_secondary)
        expect(School.phase_code_to_enum(6)).to eq(:sixteen_plus)
        expect(School.phase_code_to_enum(7)).to eq(:all_through)
      end

      it "returns nil for an unknown phase code" do
        expect(School.phase_code_to_enum(999)).to be_nil
        expect(School.phase_code_to_enum(nil)).to be_nil
      end
    end
  end

  describe ".school_type_group_code_to_enum" do
    it "returns the correct symbol for a valid school type group code" do
      expect(School.school_type_group_code_to_enum(1)).to eq(:colleges)
      expect(School.school_type_group_code_to_enum(2)).to eq(:universities)
      expect(School.school_type_group_code_to_enum(3)).to eq(:independent_schools)
      expect(School.school_type_group_code_to_enum(4)).to eq(:la_maintained)
      expect(School.school_type_group_code_to_enum(5)).to eq(:special_schools)
      expect(School.school_type_group_code_to_enum(6)).to eq(:welsh_schools)
      expect(School.school_type_group_code_to_enum(9)).to eq(:other)
      expect(School.school_type_group_code_to_enum(10)).to eq(:academies)
      expect(School.school_type_group_code_to_enum(11)).to eq(:free_schools)
      expect(School.school_type_group_code_to_enum(13)).to eq(:online)
    end

    it "returns nil for an unknown school type group code" do
      expect(School.school_type_group_code_to_enum(999)).to be_nil
      expect(School.school_type_group_code_to_enum(nil)).to be_nil
    end
  end

  describe ".school_type_code_to_enum" do
    it "returns the correct symbol for a valid school type code" do
      expect(School.school_type_code_to_enum(1)).to eq(:community_school)
      expect(School.school_type_code_to_enum(2)).to eq(:voluntary_aided_school)
      expect(School.school_type_code_to_enum(3)).to eq(:voluntary_controlled_school)
      expect(School.school_type_code_to_enum(5)).to eq(:foundation_school)
      expect(School.school_type_code_to_enum(6)).to eq(:city_technology_college)
      expect(School.school_type_code_to_enum(7)).to eq(:community_special_school)
      expect(School.school_type_code_to_enum(8)).to eq(:non_maintained_special_school)
      expect(School.school_type_code_to_enum(10)).to eq(:other_independent_special_school)
      expect(School.school_type_code_to_enum(11)).to eq(:other_independent_school)
      expect(School.school_type_code_to_enum(12)).to eq(:foundation_special_school)
      expect(School.school_type_code_to_enum(14)).to eq(:pupil_referral_unit)
      expect(School.school_type_code_to_enum(15)).to eq(:local_authority_nursery_school)
      expect(School.school_type_code_to_enum(18)).to eq(:further_education)
      expect(School.school_type_code_to_enum(24)).to eq(:secure_unit)
      expect(School.school_type_code_to_enum(25)).to eq(:offshore_school)
      expect(School.school_type_code_to_enum(26)).to eq(:service_childrens_education)
      expect(School.school_type_code_to_enum(27)).to eq(:miscellaneous)
      expect(School.school_type_code_to_enum(28)).to eq(:academy_sponsor_led)
      expect(School.school_type_code_to_enum(29)).to eq(:higher_education_institution)
      expect(School.school_type_code_to_enum(30)).to eq(:welsh_establishment)
      expect(School.school_type_code_to_enum(31)).to eq(:sixth_form_centre)
      expect(School.school_type_code_to_enum(32)).to eq(:special_post_16_institutions)
      expect(School.school_type_code_to_enum(33)).to eq(:academy_special_sponsor_led)
      expect(School.school_type_code_to_enum(34)).to eq(:academy_converter)
      expect(School.school_type_code_to_enum(35)).to eq(:free_school)
      expect(School.school_type_code_to_enum(36)).to eq(:free_school_special)
      expect(School.school_type_code_to_enum(37)).to eq(:british_school_oversea)
      expect(School.school_type_code_to_enum(38)).to eq(:free_school_alternative_provider)
      expect(School.school_type_code_to_enum(39)).to eq(:free_school_16_to_19)
      expect(School.school_type_code_to_enum(40)).to eq(:university_technical_college)
      expect(School.school_type_code_to_enum(41)).to eq(:studio_school)
      expect(School.school_type_code_to_enum(42)).to eq(:academy_alternative_provision_converter)
      expect(School.school_type_code_to_enum(43)).to eq(:academy_alternative_provision_sponsor_led)
      expect(School.school_type_code_to_enum(44)).to eq(:academy_special_converter)
      expect(School.school_type_code_to_enum(45)).to eq(:academy_16_to_19_converter)
      expect(School.school_type_code_to_enum(46)).to eq(:academy_16_to_19_sponsor_led)
      expect(School.school_type_code_to_enum(49)).to eq(:online_provider)
      expect(School.school_type_code_to_enum(56)).to eq(:institution_funded_by_other_government_department)
      expect(School.school_type_code_to_enum(57)).to eq(:academy_secure_16_to_19)
    end

    it "returns nil for an unknown school type code" do
      expect(School.school_type_code_to_enum(999)).to be_nil
      expect(School.school_type_code_to_enum(nil)).to be_nil
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
end
