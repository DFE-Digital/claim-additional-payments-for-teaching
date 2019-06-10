require "rails_helper"

describe FormHelper do
  let(:claim) { TslrClaim.new }

  describe "#form_group_tag" do
    it "wraps the supplied block in a form group <div> tag" do
      expect(helper.form_group_tag(claim) { content_tag(:div) }).to include('<div class="govuk-form-group"><div></div></div>')
    end

    context "when supplied with an object that has errors" do
      before do
        claim.errors.add(:attribute, message: "Test error")
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

  describe "#css_classes_for_input" do
    it "adds the correct css class" do
      expect(helper.css_classes_for_input(claim, :attribute) {}).to include("govuk-input")
    end

    it "adds the error class when there are errors" do
      claim.errors.add(:attribute, message: "Test error")

      expect(helper.css_classes_for_input(claim, :attribute) {}).to include("govuk-input--error")
    end

    it "keeps any existing css classes" do
      expect(helper.css_classes_for_input(claim, :attribute, "class-one class-two") {}).to include("class-one class-two")
    end
  end

  describe "#css_classes_for_select" do
    it "adds the correct css class" do
      expect(helper.css_classes_for_select(claim, :attribute) {}).to include("govuk-select")
    end

    it "adds the error class when there are errors" do
      claim.errors.add(:attribute, message: "Test error")

      expect(helper.css_classes_for_select(claim, :attribute) {}).to include("govuk-select--error")
    end
  end
end
