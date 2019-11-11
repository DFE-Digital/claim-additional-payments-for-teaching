require "rails_helper"

describe ApplicationHelper do
  describe "#currency_value_for_number_field" do
    let(:value) { 1000.1 }

    it "formats the number to two decimal places and is suitable for a number_field" do
      expect(helper.currency_value_for_number_field(value)).to eql("1000.10")
    end

    context "when no value exists" do
      let(:value) { nil }

      it "does no formatting and just returns nil" do
        expect(helper.currency_value_for_number_field(value)).to be_nil
      end
    end
  end

  describe "page_title" do
    it "returns a title for the page that follows the guidance of the design system" do
      expect(page_title("Some Title")).to eq("Some Title - #{I18n.t("student_loans.policy_name")} - GOV.UK")
    end

    it "includes an optional error prefix" do
      title = page_title("Some Title", show_error: true)

      expect(title).to eq("Error - Some Title - #{I18n.t("student_loans.policy_name")} - GOV.UK")
    end
  end

  describe "#support_email_address" do
    it "defaults to the generic support address" do
      expect(support_email_address).to eq t("support_email_address")
    end

    it "returns a policy-specific email address" do
      expect(support_email_address("student-loans")).to eq t("student_loans.support_email_address")
      expect(support_email_address("maths-and-physics")).to eq t("maths_and_physics.support_email_address")
    end
  end

  describe "#policy_service_name" do
    it "defaults to the generic service name" do
      expect(policy_service_name).to eq t("service_name")
    end

    it "returns a policy-specific service name" do
      expect(policy_service_name("student-loans")).to eq t("student_loans.policy_name")
      expect(policy_service_name("maths-and-physics")).to eq t("maths_and_physics.policy_name")
    end
  end
end
