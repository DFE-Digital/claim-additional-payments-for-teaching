require "rails_helper"

describe GovukFormHelper do
  let(:claim) { Claim.new }

  describe "#form_group_tag" do
    it "wraps the supplied block in a form group <div> tag" do
      expect(helper.form_group_tag(claim) { content_tag(:div) }).to eq('<div class="govuk-form-group"><div></div></div>')
    end

    context "when supplied with an object that has errors" do
      before do
        claim.errors.add(:attribute, "Test error")
      end

      it "adds the error class" do
        expect(helper.form_group_tag(claim) {}).to have_css(".govuk-form-group--error")
      end

      context "and an attribute is supplied" do
        it "does not add error class when there are no errors on the attribute" do
          expect(helper.form_group_tag(claim, :a_different_attribute) {}).not_to have_css(".govuk-form-group--error")
        end

        it "adds the error class when there are errors on the attribute" do
          expect(helper.form_group_tag(claim, :attribute) {}).to have_css(".govuk-form-group--error")
        end
      end
    end
  end

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

  describe "#css_classes_for_select" do
    it "adds the correct css class" do
      expect(helper.css_classes_for_select(claim, :attribute) {}).to eq("govuk-select")
    end

    it "adds the error class when there are errors" do
      claim.errors.add(:attribute, "Test error")

      expect(helper.css_classes_for_select(claim, :attribute) {}).to eq("govuk-select govuk-select--error")
    end
  end
end
