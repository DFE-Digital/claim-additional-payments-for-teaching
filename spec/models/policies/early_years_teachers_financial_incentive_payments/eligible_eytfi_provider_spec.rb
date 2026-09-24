require "rails_helper"

RSpec.describe Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider do
  describe "::search" do
    context "when name contains apostrophe and search term does not" do
      before do
        create(
          :eligible_eytfi_provider,
          name: "St John's School"
        )
      end

      it "returns a match" do
        expect(described_class.search("johns").count).to eql 1
      end
    end

    context "when name contains hyphen and search term does not" do
      before do
        create(
          :eligible_eytfi_provider,
          name: "St John-s School"
        )
      end

      it "returns a match" do
        expect(described_class.search("johns").count).to eql 1
      end
    end

    context "when name does not contain special characters + search term does" do
      before do
        create(
          :eligible_eytfi_provider,
          name: "St Johns School"
        )
      end

      it "returns a match" do
        expect(described_class.search("john-s").count).to eql 1
      end
    end

    context "when searching by postcode" do
      before do
        create(
          :eligible_eytfi_provider,
          name: "St Johns School",
          postcode: "NE1 6EE"
        )
      end

      it "returns a match" do
        expect(described_class.search("ne16ee").count).to eql 1
      end
    end
  end
end
