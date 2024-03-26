require "rails_helper"

RSpec.feature "Combined journey" do
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, teacher_id_enabled: false) }

  scenario "Teacher ID is disabled on the policy configuration" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))

    expect(page).not_to have_link "Back"
  end
end
