require "rails_helper"

RSpec.feature "TSLR journey" do
  let!(:policy_configuration) { create(:policy_configuration, :student_loans, teacher_id_enabled: false) }

  scenario "Teacher ID is disabled on the policy configuration" do
    visit landing_page_path(StudentLoans.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("student_loans.landing_page"))
    click_on "Start now"

    # - Select qts year
    expect(page).to have_text(I18n.t("questions.qts_award_year"))

    expect(page).not_to have_link "Back"
  end
end
