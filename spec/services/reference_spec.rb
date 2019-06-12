require "rails_helper"

RSpec.describe Reference do
  subject { described_class.new }

  describe "to_s" do
    let(:reference) { subject.to_s }

    it "is 8 characters long" do
      expect(reference.length).to eq(8)
    end

    it "only contains the specified characters" do
      expect(reference).to match(/\A[0-9A-Z]+\Z/)
    end
  end
end
