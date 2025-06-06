require "rails_helper"

RSpec.describe "IRP continuous employment admin task" do
  let!(:journey_configuration) { create(:journey_configuration, :international_relocation_payments) }

  let(:eligibility) do
    build(
      :international_relocation_payments_eligibility,
      :eligible,
      breaks_in_employment: false
    )
  end

  let!(:claim) do
    create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility:
    )
  end

  let!(:admin) { sign_in_as_service_operator }

  scenario "pass task" do
    visit admin_claims_path
    click_link claim.reference

    click_link I18n.t("admin.tasks.continuous_employment.title")

    # it shows claimant answer
    expect(page).to have_text("Breaks in employmentNo")

    click_button "Save and continue"

    expect(page).to have_content "There is a problem"

    choose "form-employment-breaks-field" # no
    expect {
      click_button "Save and continue"
    }.to change(Task, :count).by(1)

    click_link "Continuous employment"

    expect(page).to have_content "Passed"
    expect(page).to have_content "Has the claimant had any breaks in employment?No"
    expect(page).not_to have_content "Was the reason for this break statutory?"
  end

  scenario "pass task with statutory breaks permitted" do
    visit admin_claims_path
    click_link claim.reference

    click_link I18n.t("admin.tasks.continuous_employment.title")

    # it shows claimant answer
    expect(page).to have_text("Breaks in employmentNo")

    choose "form-employment-breaks-true-field" # yes
    click_button "Save and continue"

    expect(page).to have_content "There is a problem"
    choose "form-statutory-field-error" # yes
    expect {
      click_button "Save and continue"
    }.to change(Task, :count).by(1)

    click_link "Continuous employment"

    expect(page).to have_content "Passed"
    expect(page).to have_content "Has the claimant had any breaks in employment?Yes"
    expect(page).to have_content "Were all the breaks taken for statutory reasons?Yes"
  end

  scenario "fail task" do
    visit admin_claims_path
    click_link claim.reference

    click_link I18n.t("admin.tasks.continuous_employment.title")

    # it shows claimant answer
    expect(page).to have_text("Breaks in employmentNo")

    choose "form-employment-breaks-true-field" # yes
    click_button "Save and continue"

    expect(page).to have_content "There is a problem"
    choose "form-statutory-field" # no
    expect {
      click_button "Save and continue"
    }.to change(Task, :count).by(1)

    click_link "Continuous employment"

    expect(page).to have_content "Failed"
    expect(page).to have_content "Has the claimant had any breaks in employment?Yes"
    expect(page).to have_content "Were all the breaks taken for statutory reasons?No"
  end
end
