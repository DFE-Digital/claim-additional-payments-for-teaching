require "rails_helper"

RSpec.describe Reference do
  let(:reference) { Reference.new }

  describe "to_s" do
    it "is 8 characters long" do
      expect(reference.to_s.length).to eq(8)
    end

    it "contains only numbers and capital letters, excluding 0 and O" do
      expect(reference.to_s).to match(/\A[1-9A-NP-Z]+\Z/)
    end
  end
end
