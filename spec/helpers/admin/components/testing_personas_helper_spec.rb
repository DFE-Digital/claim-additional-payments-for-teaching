require "rails_helper"

RSpec.describe Admin::Components::TestingPersonasHelper do
  subject(:helper) { Object.new.extend(described_class) }

  describe "#personas" do
    it "loads the static registry in non-production environments" do
      expect(TestingPersonaRegistry.testing_personas).to include(hash_including(title: "Early years payment practitioner"))
    end

    it "tags every persona spec as a testing persona" do
      registry_specs = TestingPersonaRegistry.testing_personas.map { |persona| persona[:spec] }

      missing_tags = registry_specs.reject do |path|
        source = File.read(Rails.root.join(path))
        source.match?(/RSpec\.(?:feature|describe)\b.*:testing_persona/)
      end

      expect(missing_tags).to be_empty, "Missing :testing_persona tag in #{missing_tags.inspect}"
    end

    it "raises if a persona title no longer matches its spec file" do
      persona = {
        title: "this title definitely does not exist",
        scenario: "happy path",
        spec: "spec/features/early_years_teachers_financial_incentive_payments/happy_path_spec.rb"
      }

      expect { TestingPersonaRegistry.validate_personas!(personas: [persona]) }.to raise_error(/Title drift|does not exist/)
    end

    it "returns an empty array in production" do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Rails.env).to receive(:review_app_like?).and_return(false)

      expect(TestingPersonaRegistry.testing_personas).to eq([])
    end

    it "keeps testing personas available in review and staging-like environments" do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(Rails.env).to receive(:review_app_like?).and_return(true)

      expect(TestingPersonaRegistry.testing_personas).to include(hash_including(title: "Early years payment practitioner"))
    end

    it "only references journeys that exist" do
      expect(helper.personas.map { |persona| persona[:journey_name] }.uniq - Journeys.all.map(&:full_name).uniq).to be_empty
    end

    it "returns a display label for each journey" do
      expect(Journeys.all.map(&:full_name)).to all(be_present)
    end

    it "orders successful personas before ineligible ones" do
      allow(TestingPersonaRegistry).to receive(:testing_personas).and_return([
        {
          title: "Ineligible example",
          outcome: "ineligible",
          criteria: "The user is turned away.",
          description: "A claimant is rejected.",
          journey: Journeys::TargetedRetentionIncentivePayments,
          journey_name: Journeys::TargetedRetentionIncentivePayments.full_name,
          spec: "spec/features/example_ineligible_spec.rb",
          scenario: "ineligible path"
        },
        {
          title: "Successful example",
          outcome: "success",
          criteria: "The user completes the claim.",
          description: "A claimant reaches confirmation.",
          journey: Journeys::TargetedRetentionIncentivePayments,
          journey_name: Journeys::TargetedRetentionIncentivePayments.full_name,
          spec: "spec/features/example_success_spec.rb",
          scenario: "successful path"
        }
      ])

      expect(helper.journey_personas(Journeys::TargetedRetentionIncentivePayments).map { |persona| persona[:title] }).to eq(["Successful example", "Ineligible example"])
    end

    it "has a title, outcome, criteria and scenario for every persona", :aggregate_failures do
      helper.personas.each do |persona|
        expect(persona[:title]).to be_present, persona[:spec]
        expect(persona[:outcome]).to be_in(%w[success ineligible]), "#{persona[:spec]}: #{persona[:title]}"
        expect(persona[:acceptance_criteria]).to be_present, "#{persona[:spec]}: #{persona[:title]}"
        expect(persona[:scenario]).to be_present, "#{persona[:spec]}: #{persona[:title]} is not followed by a scenario"
      end
    end
  end
end
