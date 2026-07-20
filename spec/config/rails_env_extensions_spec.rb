require "rails_helper"

RSpec.describe RailsEnvExtensions do
  describe "#enable_home_components?" do
    it "returns true for test, staging, and review apps" do
      %w[test staging review-123].each do |environment_name|
        allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return(environment_name)

        expect(Rails.env.enable_home_components?).to be(true)
      end
    end

    it "returns false for production" do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return(nil)

      expect(Rails.env.enable_home_components?).to be(false)
    end
  end

  describe "#test_app?" do
    it "returns true for test" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("test")

      expect(Rails.env.test_app?).to be(true)
    end

    it "returns false for non-test environments" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("staging")

      expect(Rails.env.test_app?).to be(false)
    end
  end

  describe "#staging_app?" do
    it "returns true for staging" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("staging")

      expect(Rails.env.staging_app?).to be(true)
    end

    it "returns false for non-staging environments" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("test")

      expect(Rails.env.staging_app?).to be(false)
    end
  end

  describe "#review_app?" do
    it "returns true for review apps" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("review-123")

      expect(Rails.env.review_app?).to be(true)
    end

    it "returns false for non-review apps" do
      allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("staging")

      expect(Rails.env.review_app?).to be(false)
    end
  end
end
