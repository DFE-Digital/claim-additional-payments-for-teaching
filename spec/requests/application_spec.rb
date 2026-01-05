require "rails_helper"

RSpec.describe "Application", type: :request do
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
