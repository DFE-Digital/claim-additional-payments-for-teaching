require "rails_helper"

RSpec.feature "Managing Levelling Up Premium Payments school awards" do
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

  scenario "downloading school awards" do
    sign_in_as_service_operator

    click_on "Manage services"

    expect(page).to have_content("Claim Additional Payments for Teaching")
    within(find("tr[data-policy-configuration-id=\"#{policy_configuration.id}\"]")) do
      click_on "Change"
    end

    # When no awards exist
    expect(page).to have_text "No award amounts present for academic year #{policy_configuration.current_academic_year}."
    expect(page).not_to have_button "Download CSV"

    # When awards exist
    freeze_time do
      award = create(:levelling_up_premium_payments_award, academic_year: policy_configuration.current_academic_year)
      create(:levelling_up_premium_payments_award, academic_year: policy_configuration.current_academic_year - 1)

      visit current_path
      expect(page).to have_text "The award amounts for academic year #{policy_configuration.current_academic_year} were updated on #{Time.zone.now.strftime("%-d %B %Y")}"

      within "#download" do
        expect(page).to have_select "Academic year", options: [policy_configuration.current_academic_year, policy_configuration.current_academic_year - 1]
        expect(page).to have_button "Download CSV"

        select policy_configuration.current_academic_year, from: "academic_year"
        click_button "Download CSV"

        expect(page.body).to eq("school_urn,award_amount\n#{award.school_urn},#{award.award_amount}\n")
      end
    end
  end

end
