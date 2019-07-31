require "rails_helper"

RSpec.describe "Static pages", type: :request do
  %i[privacy_policy terms_conditions cookies accessibility_statement].each do |static_page|
    it "renders the #{static_page} page" do
      get public_send("#{static_page}_path")

      expect(response).to be_successful
    end
  end
end
