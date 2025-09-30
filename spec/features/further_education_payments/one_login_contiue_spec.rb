require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:college) { create(:school, :further_education, :fe_eligible) }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }
  let(:one_login_uid) { SecureRandom.uuid }

  scenario "has OL account with existing partial eligibility and continues" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    click_button "Sign out"

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("You have already started an eligibility check")
    choose "Continue with the eligibility check that you have already started"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
  end

  scenario "has OL account with existing partial eligibility but starts anew" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    click_button "Sign out"

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("You have already started an eligibility check")
    choose "Start a new eligibility check"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
  end

  scenario "has OL account with existing ineligible check and continues" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    click_button "Sign out"

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "Yes"
    click_button "Continue"

    mock_one_login_auth(uid: one_login_uid)

    expect(page).to have_content("Sign in with GOV.UK One Login")
    fill_in "One Login UID", with: one_login_uid
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
  end

  def and_college_exists
    college
  end
end
