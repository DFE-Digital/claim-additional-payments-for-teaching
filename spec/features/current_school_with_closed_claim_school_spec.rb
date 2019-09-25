require "rails_helper"

RSpec.feature "Current school with closed claim school" do
  scenario "Skips where teaching question" do
    start_claim
    choose_qts_year
    choose_currently_teaching
    choose_school schools(:the_samuel_lister_academy)

    expect(page).to have_text(I18n.t("questions.current_school"))
  end
end
