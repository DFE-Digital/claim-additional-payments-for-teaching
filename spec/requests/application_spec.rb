require "rails_helper"

RSpec.describe "Application", type: :request do
  describe "root redirect in production" do
    before do
      allow(Rails.env).to receive(:enable_home_components?).and_return(false)
      Rails.application.reload_routes!
    end

    after do
      allow(Rails.env).to receive(:enable_home_components?).and_return(true)
      Rails.application.reload_routes!
    end

    it "redirects the home route to gov.uk" do
      get "/"

      expect(response).to redirect_to(Rails.application.config.guidance_url)
      expect(Rails.application.config.guidance_url).to start_with("https://www.gov.uk/")
    end
  end

  describe "#handle_unwanted_requests" do
    before do
      ActionController::Base.allow_forgery_protection = true
    end

    after do
      ActionController::Base.allow_forgery_protection = false
    end

    it "ignores CSRF checks" do
      post "/RANDOMSTRING.txt", headers: {"X-CSRF-Token" => "invalid_token"}
      expect(response.code).to eq "404"
    end
  end
end
