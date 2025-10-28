require "rails_helper"

RSpec.describe GovukFormHelper do
  let(:claim) { Claim.new }

  describe "#errors_tag" do
    let(:claim) { Claim.new }

    it "returns correctly formatted error messages" do
      claim.errors.add(:attribute, "Test error one")
      claim.errors.add(:attribute, "Test error two")

      error_message = helper.errors_tag(claim, :attribute)

      expect(error_message).to have_css(".govuk-error-message")
      expect(error_message).to include('<span class="govuk-visually-hidden">Error:</span> Test error one<br>')
      expect(error_message).to include('<span class="govuk-visually-hidden">Error:</span> Test error two')
    end

    it "only returns if there is a error for the attribute" do
      claim.errors.add(:attribute, "Test error")

      expect(helper.errors_tag(claim, :a_different_attribute)).to be_nil
      expect(helper.errors_tag(claim, :attribute)).to be_truthy
    end
  end

  describe "#css_classes_for_input" do
    it "adds the correct css class" do
      expect(helper.css_classes_for_input(claim, :attribute) {}).to eq("govuk-input")
    end

    it "adds the error class when there are errors" do
      claim.errors.add(:attribute, "Test error")

      expect(helper.css_classes_for_input(claim, :attribute) {}).to eq("govuk-input govuk-input--error")
    end

    it "keeps any existing css classes" do
      expect(helper.css_classes_for_input(claim, :attribute, "class-one class-two") {}).to eq("class-one class-two govuk-input")
    end
  end
end
