require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  let(:claim) { Claim.order(:created_at).last }
  let(:eligibility) { claim.eligibility }

  before do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
    visit claim_path(StudentLoans.routing_name, "check-your-answers")
  end

  scenario "Teacher can edit a field" do
    old_number = claim.national_insurance_number
    new_number = "AB123456C"

    expect {
      find("a[href='#{claim_path(StudentLoans.routing_name, "national-insurance-number")}']").click
      fill_in "National Insurance number", with: new_number
      click_on "Continue"
    }.to change {
      claim.reload.national_insurance_number
    }.from(old_number).to(new_number)

    expect(page).to have_content("Check your answers before sending your application")
  end

  scenario "Teacher changes their year" do
    find("a[href='#{claim_path(StudentLoans.routing_name, "qts-year")}']").click

    expect(find("#claim_eligibility_attributes_qts_award_year_on_or_after_september_2013").checked?).to eq(true)

    choose I18n.t("student_loans.questions.qts_award_years.before_september_2013")
    click_on "Continue"

    expect(eligibility.reload.qts_award_year).to eq("before_september_2013")

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training on or after 1 September 2013.")
  end

  scenario "Teacher changes the subjects they taught" do
    find("a[href='#{claim_path(StudentLoans.routing_name, "subjects-taught")}']").click

    expect(find("#eligible_subjects_physics_taught").checked?).to eq(true)

    uncheck I18n.t("student_loans.questions.eligible_subjects.physics_taught"), visible: false

    check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
    check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

    click_on "Continue"

    expect(eligibility.reload.physics_taught).to eq(false)
    expect(eligibility.biology_taught).to eq(true)
    expect(eligibility.chemistry_taught).to eq(true)

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
  end

  scenario "Teacher changes their leadership position to no" do
    claim.eligibility.had_leadership_position = true
    claim.save!

    find("a[href='#{claim_path(StudentLoans.routing_name, "leadership-position")}']").click

    choose "No"
    click_on "Continue"

    expect(eligibility.reload.had_leadership_position).to eq(false)

    expect(eligibility.reload.mostly_performed_leadership_duties).to eq(nil)

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
  end

  context "Teacher changes their leadership position to yes" do
    before do
      claim.eligibility.had_leadership_position = false
      claim.save!

      find("a[href='#{claim_path(StudentLoans.routing_name, "leadership-position")}']").click

      choose "Yes"
      click_on "Continue"
    end

    scenario "and spent less than half their time performing leadership duties" do
      expect(eligibility.reload.had_leadership_position).to eq(true)
      expect(eligibility.reload.mostly_performed_leadership_duties).to eq(nil)

      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "mostly-performed-leadership-duties"))

      choose "No"
      click_on "Continue"

      expect(eligibility.reload.mostly_performed_leadership_duties).to eq(false)
      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    end

    scenario "and spent more than half their time performing leadership duties" do
      choose "Yes"
      click_on "Continue"

      expect(eligibility.reload.mostly_performed_leadership_duties).to eq(true)

      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between 6 April 2018 and 5 April 2019.")
    end
  end

  context "Teacher changes claim school to another eligible school" do
    let!(:new_claim_school) { create(:school, :student_loan_eligible, name: "Claim School") }

    before do
      find("a[href='#{claim_path(StudentLoans.routing_name, "claim-school")}']").click

      choose_school new_claim_school
    end

    scenario "and is still teaching eligible subjects at the new claim school" do
      expect(eligibility.reload.claim_school).to eql new_claim_school
      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "subjects-taught"))

      check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
      check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

      click_on "Continue"

      expect(eligibility.reload.biology_taught).to eq(true)
      expect(eligibility.chemistry_taught).to eq(true)

      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "still-teaching"))

      choose_still_teaching "Yes, at Claim School"

      expect(eligibility.reload.employment_status).to eql("claim_school")
      expect(eligibility.current_school).to eql new_claim_school

      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    end

    scenario "and still teaching eligible subjects at a different school" do
      check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
      check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

      click_on "Continue"

      choose_still_teaching "Yes, at another school"

      fill_in :school_search, with: "Hampstead"
      click_on "Search"

      choose "Hampstead School"
      click_on "Continue"

      expect(eligibility.reload.employment_status).to eql("different_school")
      expect(eligibility.reload.current_school).to eql schools(:hampstead_school)

      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    end

    scenario "and no longer teaching" do
      check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
      check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

      click_on "Continue"

      choose_still_teaching "No"

      expect(eligibility.reload.employment_status).to eq("no_school")
      expect(page).to have_text("You’re not eligible")
      expect(page).to have_text("You can only get this payment if you’re still employed to teach at a school.")
    end
  end

  scenario "Teacher changes the are you still employed question (employment_status)" do
    find("a[href='#{claim_path(StudentLoans.routing_name, "still-teaching")}']").click

    choose "Yes, at Penistone Grammar School"
    click_on "Continue"

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    expect(eligibility.reload.employment_status).to eq("claim_school")
    expect(eligibility.current_school).to eq(schools(:penistone_grammar_school))
  end

  scenario "Teacher changes the current school from same school to different school" do
    eligibility.update!(employment_status: "claim_school")

    find("a[href='#{claim_path(StudentLoans.routing_name, "still-teaching")}']").click

    choose "Yes, at another school"
    click_on "Continue"

    fill_in :school_search, with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"
    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    expect(eligibility.reload.employment_status).to eq("different_school")
    expect(eligibility.current_school).to eq(schools(:hampstead_school))
  end

  scenario "changing student loan answer to “No” resets the other student loan-related answers" do
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    find("a[href='#{claim_path(StudentLoans.routing_name, "student-loan")}']").click

    choose "No"
    click_on "Continue"

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    expect(claim.reload.has_student_loan).to eq false
    expect(claim.student_loan_country).to be_nil
    expect(claim.student_loan_courses).to be_nil
    expect(claim.student_loan_start_date).to be_nil
    expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
  end

  scenario "changing student loan country forces dependent questions to be re-answered" do
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    find("a[href='#{claim_path(StudentLoans.routing_name, "student-loan-country")}']").click

    choose "Wales"
    click_on "Continue"

    choose "1"
    click_on "Continue"

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
    expect(claim.reload.has_student_loan).to eq true
    expect(claim.student_loan_country).to eq StudentLoan::WALES
    expect(claim.student_loan_courses).to eq "one_course"
    expect(claim.student_loan_start_date).to eq StudentLoan::BEFORE_1_SEPT_2012
    expect(claim.student_loan_plan).to eq StudentLoan::PLAN_1
  end

  scenario "user cannot change the value of an identity field that was acquired from Verify" do
    claim.update!(verified_fields: ["payroll_gender"])
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    expect(page).to_not have_content(I18n.t("questions.payroll_gender"))
    expect(page).to_not have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "gender")}']")

    expect {
      visit claim_path(StudentLoans.routing_name, "gender")
    }.to raise_error(ActionController::RoutingError)
  end

  scenario "user can change the answer to an identity question that wasn't acquired from Verify" do
    claim.update!(verified_fields: [])
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    expect(page).to have_content(I18n.t("questions.payroll_gender"))
    expect(page).to have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "gender")}']")

    find("a[href='#{claim_path(StudentLoans.routing_name, "gender")}']").click
    choose "I don't know"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("dont_know")
  end

  scenario "when changing the student loan repayment amount the user can change answer and it preserves two decimal places" do
    claim.eligibility.update!(student_loan_repayment_amount: 100.1)
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    expect(page).to have_content("£100.10")
    find("a[href='#{claim_path(StudentLoans.routing_name, "student-loan-amount")}']").click

    expect(find("#claim_eligibility_attributes_student_loan_repayment_amount").value).to eq("100.10")
    fill_in I18n.t("student_loans.questions.student_loan_amount"), with: "150.20"
    click_on "Continue"

    expect(page).to have_content("£150.20")
  end
end
