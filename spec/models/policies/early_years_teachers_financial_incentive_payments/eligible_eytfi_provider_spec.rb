require "rails_helper"

RSpec.describe Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider do
  it "normalizes registered person names on assignment and lookup" do
    provider = create(:eligible_eytfi_provider, registered_person_name: "  Oak Group  ")

    expect(provider.reload.registered_person_name).to eq("oak group")
    expect(described_class.where(registered_person_name: [" OAK GROUP "])).to include(provider)
  end

  it "allows a missing registered person name" do
    provider = build(:eligible_eytfi_provider, registered_person_name: nil)

    expect(provider.registered_person_name).to be_nil
  end

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
