require "rails_helper"

RSpec.feature "Backlinking during a claim" do
  scenario "when there is an error" do
    create(:journey_configuration, :additional_payments)
    lup_school = create(:school, :levelling_up_premium_payments_eligible)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    expect(page).to have_link("Back")
    click_on "Continue without signing in"

    expect(page).to have_content("Which school do you teach at?")
    expect(page).to have_link("Back")
    choose_school lup_school

    expect(page).to have_content("Are you currently teaching as a qualified teacher?")
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content("Are you currently employed as a supply teacher?")
    choose "No"
    click_on "Continue"

    expect(page).to have_content("Tell us if you are currently under any performance measures or disciplinary action")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    expect(page).to have_content("Which route into teaching did you take?")
    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_content("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    choose "2020 to 2021"
    click_on "Continue"

    expect(page).to have_content("Which subject did you do your undergraduate initial teacher training (ITT) in?")
    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_content("Do you spend at least half of your contracted hours teaching eligible subjects?")
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content("Check your answers")
    click_on "Continue"

    click_on "Apply now"

    click_on "Continue"

    expect(page).to have_content("What is your full name?")
    click_on "Continue"

    expect(page).to have_content("What is your full name?")
    expect(page).to have_link("Back")
  end

  scenario "Student Loans journey" do
    create(:journey_configuration, :student_loans)
    school = create(:school, :student_loans_eligible)
    visit new_claim_path(Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)
    skip_tid
    expect(page).to have_link("Back")
    choose_qts_year
    expect(page).to have_link("Back")
    choose_school school
    click_on "Back"
    expect(page).to have_current_path("/student-loans/claim-school", ignore_query: true)
    click_on "Back"
    expect(page).to have_text(I18n.t("student_loans.forms.qts_year.questions.qts_award_year"))
    click_on "Back"
    expect(page).to have_text("Use DfE Identity to sign in")
    expect(page).to have_link("Back")
    click_on "Back"
    expect(page).to have_text("Claim back student loan repayments if you're a teacher")
  end

  scenario "ECP/LUP journey" do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023))
    lup_school = create(:school, :levelling_up_premium_payments_eligible)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    expect(page).to have_link("Back")
    click_on "Continue without signing in"

    expect(page).to have_link("Back")
    choose_school lup_school
    expect(page).to have_link("Back")

    # go to deadend
    choose "No"
    click_on "Continue"
    expect(page).to have_link("Back")
    choose "None of the above"
    click_on "Continue"
    choose "No"
    click_on "Continue"
    expect(page).to have_no_link("Back")
  end

  scenario "ECP/LUP trainee mini journey" do
    create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023))
    lup_school = create(:school, :levelling_up_premium_payments_eligible)

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    expect(page).to have_link("Back")
    click_on "Continue without signing in"

    choose_school lup_school

    choose "No, I’m a trainee teacher"
    click_on "Continue"
    click_on "Back"

    expect(page).to have_link("Back")
  end
end
