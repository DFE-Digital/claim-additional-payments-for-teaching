require "rails_helper"

RSpec.describe "Maintenance Mode", type: :request do
  context "when MAINTENANCE_MODE is set" do
    before do
      @original_maintenance_mode_value = Rails.application.config.maintenance_mode
      Rails.application.config.maintenance_mode = true
      Rails.application.reload_routes!
    end

    after do
      Rails.application.config.maintenance_mode = @original_maintenance_mode_value
      Rails.application.reload_routes!
    end

    it "shows the maintenance page" do
      get "/"
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to include("service is unavailable")
      expect(response.body).to include("You will be able to use the service later today.")
    end

    context "when the availability message is set" do
      let(:message) { "You will be able to use the service from 2pm today" }

      before do
        @original_maintenance_mode_availability_message = Rails.application.config.maintenance_mode_availability_message
        Rails.application.config.maintenance_mode_availability_message = message
      end

      after do
        Rails.application.config.maintenance_mode_availability_message = @original_maintenance_mode_availability_message
      end

      it "shows the time it will be available from" do
        get "/"
        expect(response.body).to include(message)
      end
    end

    it "redirects a GET request to the maintenance page" do
      expect(get("/contact")).to redirect_to("/")
    end

    it "redirects a POST request to the maintenance page" do
      expect(post("/claim")).to redirect_to("/")
    end
  end
end
