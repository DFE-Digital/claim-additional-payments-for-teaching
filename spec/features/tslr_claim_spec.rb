require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    claim = start_tslr_claim
    expect(page).to have_text(I18n.t("tslr.questions.qts_award_year"))

    choose_qts_year
    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))

    choose_school schools(:penistone_grammar_school)
    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text(I18n.t("tslr.questions.employment_status"))

    choose_still_teaching
    expect(claim.reload.employment_status).to eql("claim_school")
    expect(claim.current_school).to eql(schools(:penistone_grammar_school))

    expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects"))
    choose "Yes"
    click_on "Continue"

    expect(claim.reload.mostly_teaching_eligible_subjects).to eq(true)

    expect(page).to have_text(I18n.t("tslr.questions.full_name"))

    fill_in I18n.t("tslr.questions.full_name"), with: "Margaret Honeycutt"
    click_on "Continue"

    expect(claim.reload.full_name).to eql("Margaret Honeycutt")

    expect(page).to have_text(I18n.t("tslr.questions.address"))

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

    expect(page).to have_text(I18n.t("tslr.questions.date_of_birth"))
    fill_in "Day", with: "03"
    fill_in "Month", with: "7"
    fill_in "Year", with: "1990"
    click_on "Continue"

    expect(claim.reload.date_of_birth).to eq(Date.new(1990, 7, 3))

    expect(page).to have_text(I18n.t("tslr.questions.teacher_reference_number"))
    fill_in :tslr_claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    expect(page).to have_text(I18n.t("tslr.questions.national_insurance_number"))
    fill_in "National Insurance number", with: "QQ123456C"
    click_on "Continue"

    expect(claim.reload.national_insurance_number).to eq("QQ123456C")

    expect(page).to have_text(I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name))
    fill_in I18n.t("tslr.questions.student_loan_amount", claim_school_name: claim.claim_school_name), with: "1100"
    click_on "Continue"

    expect(claim.reload.student_loan_repayment_amount).to eql(1100.00)

    expect(page).to have_text(I18n.t("tslr.questions.email_address"))
    expect(page).to have_text("We will only use your email address to update you about your claim.")
    fill_in I18n.t("tslr.questions.email_address"), with: "name@example.tld"
    click_on "Continue"

    expect(claim.reload.email_address).to eq("name@example.tld")

    expect(page).to have_text(I18n.t("tslr.questions.bank_details"))
    expect(page).to have_text("We need to collect this information to pay you.")
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.bank_sort_code).to eq("123456")
    expect(claim.reload.bank_account_number).to eq("87654321")

    expect(page).to have_text("Check your answers before sending your application")

    freeze_time do
      click_on "Confirm and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    expect(page).to have_text("Claim submitted")
  end

  scenario "Teacher now works for a different school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose_still_teaching "Yes, at another school"

    expect(claim.reload.employment_status).to eql("different_school")

    fill_in "School name", with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.current_school).to eql schools(:hampstead_school)

    expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects"))
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

    choose_still_teaching "No"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You must be still working as a teacher to be eligible")
  end

  scenario "did not teach at least half their time in an eligible subject" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching

    expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects"))
    choose "No"
    click_on "Continue"

    expect(claim.reload.mostly_teaching_eligible_subjects).to eq(false)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
  end

  scenario "Teacher cannot go to mid-claim page before starting a claim" do
    visit claim_path("qts-year")
    expect(page).to have_current_path(root_path)
  end

  context "editing a response" do
    let(:claim_school) { create(:school, :tslr_eligible, name: "Claim School") }
    let(:current_school) { create(:school, :tslr_eligible, name: "Current School") }

    let(:claim) { create(:tslr_claim, :eligible_and_submittable, claim_school: claim_school, current_school: current_school) }

    before do
      allow_any_instance_of(ClaimsController).to receive(:current_claim) { claim }
    end

    scenario "Teacher can edit a field" do
      visit claim_path("check-your-answers")

      find("a[href='#{claim_path("national-insurance-number")}']").click

      fill_in "National Insurance number", with: "AB123456C"
      click_on "Continue"

      expect(claim.reload.national_insurance_number).to eq("AB123456C")
      expect(page).to have_content("Check your answers before sending your application")
    end

    scenario "Teacher sees their original claim school when editing" do
      visit claim_path("check-your-answers")

      find("a[href='#{claim_path("claim-school")}']").click

      expect(find("input[name='school_search']").value).to eq(claim.claim_school.name)
    end

    scenario "Teacher sees their original current school when editing" do
      visit claim_path("check-your-answers")

      find("a[href='#{claim_path("current-school")}']").click

      expect(find("input[name='school_search']").value).to eq(claim.current_school.name)
    end
  end
end
