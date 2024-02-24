require "rails_helper"

RSpec.feature "Combined journey" do
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, teacher_id_enabled: false) }

  scenario "Teacher ID is disabled on the policy configuration" do
    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))

    expect(page).not_to have_link "Back"
  end
end
