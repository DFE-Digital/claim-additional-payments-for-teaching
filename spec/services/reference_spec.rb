require "rails_helper"

RSpec.describe Reference do
  subject { described_class.new }

  describe "to_s" do
    let(:reference) { subject.to_s }

    it "is 8 characters long" do
      expect(reference.length).to eq(8)
    end

    it "contains only numbers and capital letters, excluding 0 and O" do
      expect(reference).to match(/\A[1-9A-NP-Z]+\Z/)
    end
  end
end
