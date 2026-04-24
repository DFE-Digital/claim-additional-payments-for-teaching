require "rails_helper"

RSpec.describe PaymentMailerHelper do
  describe "#tax_year_for" do
    it "returns the tax year spanning the given date" do
      expect(tax_year_for(Date.parse("2019-01-01"))).to eq("2018 to 2019")
    end

    context "when date is nil" do
      it "raises a NoMethodError" do
        expect { tax_year_for(nil) }.to raise_error(NoMethodError)
      end
    end
  end
end
