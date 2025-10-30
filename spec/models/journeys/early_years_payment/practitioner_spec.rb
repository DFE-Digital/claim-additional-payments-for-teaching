require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Practitioner do
  describe "#full_name" do
    it "returns full name" do
      expect(subject.full_name).to eql("Early years financial incentive payment service - Practitioner journey")
    end
  end
end
