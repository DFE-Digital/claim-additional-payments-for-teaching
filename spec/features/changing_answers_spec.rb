require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  include StudentLoansHelper

  scenario "Teacher changes an answer which is not a dependency of any of the other answers they’ve given, remaining eligible" do
    claim = start_maths_and_physics_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: "maths"))
    visit claim_path(MathsAndPhysics.routing_name, "check-your-answers")

    find("a[href='#{claim_path(MathsAndPhysics.routing_name, "initial-teacher-training-subject")}']").click

    expect(find("#claim_eligibility_attributes_initial_teacher_training_subject_maths").checked?).to eq(true)

    choose "Physics"
    click_on "Continue"

    expect(claim.eligibility.reload.initial_teacher_training_subject).to eq("physics")

    expect(current_path).to eq(claim_path(MathsAndPhysics.routing_name, "check-your-answers"))
  end

  scenario "Teacher changes an answer which is not a dependency of any of the other answers they’ve given, becoming ineligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    find("a[href='#{claim_path(StudentLoans.routing_name, "qts-year")}']").click

    expect(find("#claim_eligibility_attributes_qts_award_year_on_or_after_cut_off_date").checked?).to eq(true)

    choose_qts_year :before_cut_off_date
    click_on "Continue"

    expect(claim.eligibility.reload.qts_award_year).to eq("before_cut_off_date")

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training in or after the academic year #{StudentLoans.first_eligible_qts_award_year.to_s(:long)}.")
  end

  scenario "Teacher changes an answer which is a dependency of some of the subsequent answers they’ve given, remaining eligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    new_claim_school = create(:school, :student_loan_eligible, name: "Claim School")

    find("a[href='#{claim_path(StudentLoans.routing_name, "claim-school")}']").click

    choose_school new_claim_school

    expect(claim.eligibility.reload.claim_school).to eql new_claim_school
    expect(claim.eligibility.physics_taught).to be_nil
    expect(claim.eligibility.biology_taught).to be_nil
    expect(claim.eligibility.employment_status).to be_nil
    expect(claim.eligibility.current_school).to be_nil

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "subjects-taught"))

    check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
    check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

    click_on "Continue"

    expect(claim.eligibility.reload.biology_taught).to eq(true)
    expect(claim.eligibility.chemistry_taught).to eq(true)

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "still-teaching"))

    choose_still_teaching "Yes, at Claim School"

    expect(claim.eligibility.reload.employment_status).to eql("claim_school")
    expect(claim.eligibility.current_school).to eql new_claim_school

    expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
  end

  scenario "Teacher changes an answer which is a dependency of some of the subsequent answers they’ve given, making them ineligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, had_leadership_position: false))
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    find("a[href='#{claim_path(StudentLoans.routing_name, "leadership-position")}']").click

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.had_leadership_position).to eq(true)
    expect(claim.eligibility.mostly_performed_leadership_duties).to be_nil

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.mostly_performed_leadership_duties).to eq(true)

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between #{StudentLoans.current_financial_year}.")
  end

  scenario "Teacher edits but does not change an answer which is a dependency of some of the subsequent answers they’ve given" do
    claim = start_maths_and_physics_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: true, has_entire_term_contract: true, employed_directly: true))
    visit claim_path(MathsAndPhysics.routing_name, "check-your-answers")

    find("a[href='#{claim_path(MathsAndPhysics.routing_name, "supply-teacher")}']").click

    expect(find("#claim_eligibility_attributes_employed_as_supply_teacher_true").checked?).to eq(true)

    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eq(true)
    expect(claim.eligibility.has_entire_term_contract).to eq(true)
    expect(claim.eligibility.employed_directly).to eq(true)

    expect(current_path).to eq(claim_path(MathsAndPhysics.routing_name, "check-your-answers"))
  end

  scenario "when changing the student loan repayment amount the user can change answer and it preserves two decimal places" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 100.1))
    visit claim_path(StudentLoans.routing_name, "check-your-answers")

    expect(page).to have_content("£100.10")
    find("a[href='#{claim_path(StudentLoans.routing_name, "student-loan-amount")}']").click

    expect(find("#claim_eligibility_attributes_student_loan_repayment_amount").value).to eq("100.10")
    fill_in student_loan_amount_question, with: "150.20"
    click_on "Continue"

    expect(page).to have_content("£150.20")
  end

  context "User changes fields that aren't related to eligibility" do
    let!(:claim) { start_student_loans_claim }
    let(:eligibility) { claim.eligibility }

    before do
      claim.update!(attributes_for(:claim, :submittable))
      eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
      visit claim_path(StudentLoans.routing_name, "check-your-answers")
    end

    scenario "Teacher can change a field that isn't related to eligibility" do
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

    scenario "user can change the answer to identity details" do
      claim.update!(govuk_verify_fields: [])
      visit claim_path(StudentLoans.routing_name, "check-your-answers")

      expect(page).to have_content(I18n.t("questions.name"))
      expect(page).to have_content(I18n.t("questions.address"))
      expect(page).to have_content(I18n.t("questions.date_of_birth"))
      expect(page).to have_content(I18n.t("questions.payroll_gender"))
      expect(page).to have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "name")}']")
      expect(page).to have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "address")}']")
      expect(page).to have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "date-of-birth")}']")
      expect(page).to have_selector(:css, "a[href='#{claim_path(StudentLoans.routing_name, "gender")}']")

      find("a[href='#{claim_path(StudentLoans.routing_name, "name")}']").click
      fill_in "First name", with: "Bobby"
      click_on "Continue"

      expect(current_path).to eq(claim_path(StudentLoans.routing_name, "check-your-answers"))
      expect(claim.reload.first_name).to eq("Bobby")
    end
  end
end
