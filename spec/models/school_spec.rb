require "rails_helper"

RSpec.describe School, type: :model do
  it { should belong_to(:local_authority) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:urn) }
  it { should validate_presence_of(:school_type_group) }
  it { should validate_presence_of(:school_type) }
  it { should validate_presence_of(:phase) }

  describe ".search" do
    it "returns schools matching the search term" do
      expect(School.search("Penistone")).to match_array([schools(:penistone_grammar_school)])
    end

    it "raises an ArgumentError when the search term has fewer than 4 characters" do
      expect(lambda { School.search("Pen") }).to raise_error(ArgumentError, School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR)
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

  describe "dfe_number" do
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
end
