require "rails_helper"

RSpec.describe JourneyFlowDefinition, type: :model do
  describe ".definition_for" do
    it "loads the structured route definition for a journey by routing name" do
      definition = described_class.definition_for("early-years-teachers-recognition-payments")

      expect(definition[:id]).to eq("early-years-teachers-recognition-payments")
      expect(definition[:edges]).to include(hash_including(from: "start", to: "nursery_search"))
    end
  end

  describe ".mermaid_for" do
    it "renders the Mermaid graph for a journey" do
      definition = described_class.mermaid_for("early-years-teachers-recognition-payments")

      expect(definition).to include("flowchart TD")
      expect(definition).to include("start --> |begin| nursery_search")
      expect(definition).to include("check_eligibility --> |ineligible| ineligible")
    end

    it "renders Mermaid for each configured journey" do
      journey_ids = Dir.glob(Rails.root.join("app/models/journey_flow_definitions/*.yml")).map do |file|
        File.basename(file, ".yml")
      end

      journey_ids.each do |journey_id|
        definition = described_class.definition_for(journey_id)
        mermaid = described_class.mermaid_for(journey_id)

        expect(definition[:id]).to eq(journey_id)
        expect(mermaid).to include("flowchart TD")
        expect(mermaid).to include("click")
      end
    end
  end
end
