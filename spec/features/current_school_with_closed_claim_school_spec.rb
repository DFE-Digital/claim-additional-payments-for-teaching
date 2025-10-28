require "rails_helper"

RSpec.feature "Current school with closed claim school" do
  let!(:claim_school) { create(:school, :student_loans_eligible, :closed) }

  before { create(:journey_configuration, :student_loans) }

  scenario "Still teaching only has two options" do
    start_student_loans_claim
    choose_school claim_school
    check "Physics"
    click_on "Continue"

    expect(page).to have_text("Yes")
    expect(page).to have_text("No")
    expect(page).not_to have_text("Yes, at #{claim_school.name}")
    expect(page).not_to have_text("Yes, at another school")

    # - Choosing yes to still teaching prompts to search for a school
    choose_still_teaching "Yes"

    session = Journeys::TeacherStudentLoanReimbursement::Session.last
    expect(session.answers.employment_status).to eq("different_school")
    expect(page).to have_text(I18n.t("student_loans.forms.current_school.question"))
    expect(page).to have_button("Continue")
  end
end
