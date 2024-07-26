require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before { create(:journey_configuration, :student_loans) }

  describe "#refresh" do
    it "updates the last_seen_at session timestamp and responds with OK" do
      start_student_loans_claim

      travel_to(1.day.from_now) do
        get refresh_session_path

        expect(session[:last_seen_at]).to eql(Time.zone.now)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
