require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    claim = start_tslr_claim
    expect(page).to have_text("Which academic year were you awarded qualified teacher status")

    choose_qts_year
    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    choose_school schools(:penistone_grammar_school)
    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")

    choose "Yes, at Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("claim_school")
    expect(claim.current_school).to eql(schools(:penistone_grammar_school))

    expect(page).to have_text("What is your full name")

    fill_in "What is your full name?", with: "Margaret Honeycutt"
    click_on "Continue"

    expect(claim.reload.full_name).to eql("Margaret Honeycutt")

    expect(page).to have_text("What is your address?")

    fill_in :tslr_claim_address_line_1, with: "123 Main Street"
    fill_in :tslr_claim_address_line_2, with: "Downtown"
    fill_in "Town or city", with: "Twin Peaks"
    fill_in "County", with: "Washington"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("123 Main Street")
    expect(claim.address_line_2).to eql("Downtown")
    expect(claim.address_line_3).to eql("Twin Peaks")
    expect(claim.address_line_4).to eql("Washington")
    expect(claim.postcode).to eql("M1 7HL")

    expect(page).to have_text("What is your date of birth?")
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"

    expect(claim.reload.date_of_birth).to eq(Date.new(1990, 7, 3))

    expect(page).to have_text("What is your teacher reference number?")
    fill_in :tslr_claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    expect(page).to have_text("What is your National Insurance number?")
    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    expect(claim.reload.national_insurance_number).to eq("QQ123456C")

    expect(page).to have_text("What is your email address?")
    expect(page).to have_text("We will only use your email address to update you about your claim.")
    fill_in "What is your email address?", with: "name@example.tld"
    click_on "Continue"

    expect(claim.reload.email_address).to eq("name@example.tld")

    expect(page).to have_text("Claim complete")
  end

  scenario "Teacher now works for a different school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose "Yes, at another school"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("different_school")

    fill_in "School name", with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.current_school).to eql schools(:hampstead_school)

    expect(page).to have_text("What is your full name")
  end

  scenario "chooses an ineligible school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:hampstead_school)

    expect(claim.reload.claim_school).to eq schools(:hampstead_school)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("Hampstead School is not an eligible school")
  end

  scenario "no longer teaching" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose "No"
    click_on "Continue"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You must be still working as a teacher to be eligible")
  end

  scenario "Teacher cannot go to mid-claim page before starting a claim" do
    visit claim_path("qts-year")
    expect(page).to have_current_path(root_path)
  end
end
