require "rails_helper"

RSpec.describe JourneyFlowDefinition, type: :model do
  describe ".definition_for" do
    it "loads the structured route definition for a journey by routing name" do
      definition = described_class.definition_for("early-years-teachers-recognition-payments")

      expect(definition[:id]).to eq("early-years-teachers-recognition-payments")
      expect(definition[:edges]).to include(hash_including(from: "start", to: "nursery_search"))
    end

    it "captures the one login flow and interim branch for further education payments" do
      definition = described_class.definition_for("further-education-payments")

      expect(definition[:edges]).to include(hash_including(from: "have_one_login_account", to: "sign_in"))
      expect(definition[:edges]).to include(hash_including(from: "sign_in", to: "existing_progress"))
      expect(definition[:edges]).to include(hash_including(from: "existing_progress", to: "check_eligibility_intro"))
    end

    it "keeps the relocation payment flow connected past postcode search" do
      definition = described_class.definition_for("get-a-teacher-relocation-payment")

      expect(definition[:edges]).to include(hash_including(from: "personal_details", to: "postcode_search"))
      expect(definition[:edges]).to include(hash_including(from: "postcode_search", to: "select_home_address"))
      expect(definition[:edges]).to include(hash_including(from: "address", to: "email_address"))
      expect(definition[:edges]).to include(hash_including(from: "personal_bank_account", to: "gender"))
      expect(definition[:edges]).to include(hash_including(from: "check_your_answers", to: "confirmation"))
    end
  end

  describe ".svg_for" do
    it "renders a server-side SVG journey graph" do
      svg = described_class.svg_for("early-years-teachers-recognition-payments")

      expect(svg).to include("<svg")
      expect(svg).to include("<path")
      expect(svg).to include("Start")
      expect(svg).to include("Nursery search")
    end

    it "creates clickable links for linkable nodes" do
      svg = described_class.svg_for("further-education-payments")

      expect(svg).to include("<a")
      expect(svg).to include("href=")
      expect(svg).to include("ineligible")
      expect(svg).to include("<polygon")
    end

    it "flags terminal exit nodes like sign-out and cancelled claims in red" do
      further_education_definition = described_class.definition_for("further-education-payments")
      early_years_definition = described_class.definition_for("early-years-teachers-recognition-payments")

      no_work_email_access = further_education_definition[:nodes].find { |node| node[:id] == "no_work_email_access" }
      claim_cancelled = early_years_definition[:nodes].find { |node| node[:id] == "claim_cancelled" }

      expect(described_class.terminating_exit_node?(no_work_email_access)).to be(true)
      expect(described_class.terminating_exit_node?(claim_cancelled)).to be(true)
      expect(described_class.terminating_exit_node?(further_education_definition[:nodes].find { |node| node[:id] == "confirmation" })).to be(false)
    end
  end
end
