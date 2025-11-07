require "rails_helper"

RSpec.feature "Claim journey does not get cached" do
  before { create(:journey_configuration, :student_loans) }

  it "redirects the user to the start of the claim journey if they go back after the claim is completed" do
    start_student_loans_claim
    journey_session = Journeys::TeacherStudentLoanReimbursement::Session.last
    journey_session.update!(
      answers: attributes_for(:student_loans_answers, :submittable)
    )

    jump_to_claim_journey_page(
      slug: "check-your-answers",
      journey_session: journey_session
    )

    expect(page).to have_text(journey_session.answers.first_name)
    click_on "Confirm and send"

    expect(current_path).to eql(claim_path(Journeys::TeacherStudentLoanReimbursement.routing_name, slug: "confirmation"))

    jump_to_claim_journey_page(
      slug: "check-your-answers",
      journey_session: journey_session
    )

    expect(page).to_not have_text(journey_session.answers.first_name)
    expect(page).to have_text("Use DfE Identity to sign in")
  end
end
