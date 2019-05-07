require "rails_helper"

RSpec.describe School, type: :model do
  it { should belong_to(:local_authority) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:urn) }
  it { should validate_presence_of(:school_type_group) }
  it { should validate_presence_of(:school_type) }
  it { should validate_presence_of(:phase) }

  describe ".search" do
    it "return schools matching the search term" do
      expect(School.search("Penistone")).to match_array([schools(:penistone_grammar_school)])
    end
  end
end
