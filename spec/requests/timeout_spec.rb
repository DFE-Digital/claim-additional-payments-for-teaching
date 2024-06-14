require "rails_helper"

RSpec.describe "Claim session timing out", type: :request do
  let(:timeout_length_in_minutes) { BasePublicController::CLAIM_TIMEOUT_LENGTH_IN_MINUTES }
  let(:journey_session) do
    Journeys::TeacherStudentLoanReimbursement::Session.last
  end

  before { create(:journey_configuration, :student_loans) }

  context "no actions performed for more than the timeout period" do
    before do
      start_student_loans_claim
    end

    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the timeout page" do
      expect(
        session[:"student-loans_journeys_session_id"]
      ).to eq journey_session.id

      travel after_expiry do
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"), params: {claim: {qts_award_year: "on_or_after_cut_off_date"}}

        expect(response).to redirect_to(timeout_claim_path)
        expect(session[:claim_id]).to be_nil
      end
    end
  end

  context "no action performed just within the timeout period" do
    before do
      start_student_loans_claim
      set_slug_sequence_in_session(journey_session, "qts-year")
    end

    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        put claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "qts-year"), params: {claim: {qts_award_year: "on_or_after_cut_off_date"}}

        expect(response).to redirect_to(claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME, "claim-school"))
      end
    end
  end
end
