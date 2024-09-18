require "rails_helper"

RSpec.describe "IRP admin tasks" do
  let!(:journey_configuration) { create(:journey_configuration, :international_relocation_payments) }

  let!(:claim) do
    create(
      :claim,
      :submitted,
      :with_student_loan,
      policy: Policies::InternationalRelocationPayments,
      eligibility: build(:international_relocation_payments_eligibility, :eligible)
    )
  end

  let!(:admin) { sign_in_as_service_operator }

  scenario "pass no previous payment task" do
    visit admin_claims_path
    click_link claim.reference

    click_link I18n.t("admin.tasks.previous_payment.title")

    expect(page).to have_content("The claimant has not received an IRP payment in AY 2023/24?")
    choose "Yes"
    click_button "Save and continue"
    click_link "Previous payment"
    expect(page).to have_content "Passed"
  end

  scenario "fail no previous payment task" do
    visit admin_claims_path
    click_link claim.reference

    click_link I18n.t("admin.tasks.previous_payment.title")

    expect(page).to have_content("The claimant has not received an IRP payment in AY 2023/24?")
    choose "No"
    click_button "Save and continue"
    click_link "Previous payment"
    expect(page).to have_content "Failed"
  end
end
