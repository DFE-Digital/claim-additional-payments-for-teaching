require "rails_helper"

RSpec.feature "Teacher Early Career Payments claims" do
  scenario "Teacher makes claim for 'Early Career Payments' claim" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # [PAGE 00] - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # TODO [PAGE 02] - Which school do you teach at
    # TODO [PAGE 03] - Select the school you teach at
    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # [PAGE 07] - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false

    # [PAGE 08] - Are you currently subject to dsiciplinary action
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # [PAGE 09] - Did you do a postgraduate ITT course or undergraduate ITT course
    expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_itt_or_undergraduate_itt_course"))

    choose "Postgraduate"
    click_on "Continue"

    expect(claim.eligibility.reload.pgitt_or_ugitt_course).to eq "postgraduate"

    # [PAGE 10] - Which subject did you do your undergraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", ug_or_pg: claim.eligibility.reload.pgitt_or_ugitt_course))

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # TODO [PAGE 11] - Which subject did you do your postgraduate ITT in
    # [PAGE 12] - Do you teach maths now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    # [PAGE 13] - In what academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year", start_or_complete: "start", ug_or_pg: claim.eligibility.pgitt_or_ugitt_course))

    choose "2018 - 2019"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"

    # TODO [PAGE 14] - In what academic year did you start your postgraduate ITT
    # TODO [PAGE 15] - Check your answers for eligibility
    # TODO [PAGE 16] - You are eligible for an early career payment
    # TODO [PAGE 20] - Personal Details
    # TODO [PAGE 21] - One Time Password
    # TODO [PAGE 22] - We have sent you reminders
    # TODO [PAGE 23] - How will we use the information you provide
    # TODO [PAGE 24] - Personal details
    # TODO [PAGE 25] - What is your address
    # TODO [PAGE 26] - Email address
    # TODO [PAGE 27] - Enter bank account details
    # TODO [PAGE 28] - What gender does your school's payroll system associate with you
    # TODO [PAGE 29] - What is your teacher reference number
    # TODO [PAGE 30] - Are you currently paying off your student loan
    # TODO [PAGE 31] - When you applied for your student loan where was your address
    # TODO [PAGE 32] - How many higher education courses did you take a student loan out for
    # TODO [PAGE 33] - When did the first year of your higher education course start
    # TODO [PAGE 34] - When did your higher education courses start
    # [PAGE 35] - Did you take out a postgraduate masters loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("early_career_payments.questions.postgraduate_masters_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.postgraduate_masters_loan).to eql true

    # TODO [PAGE 36] - Did you take out a postgraduate doctoral loan on or after 1 August 2016

    # TODO [PAGE 37] - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")

    stub_geckoboard_dataset_update

    freeze_time do
      click_on "Confirm and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # TODO [PAGE 38] - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("Claim submitted")
    expect(page).to have_text(claim.reference)
  end

  scenario "Supply Teacher makes claim for 'Early Career Payments' with a contract to teach for entire term & employed directly by school" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # [PAGE 00] - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # TODO [PAGE 02] - Which school do you teach at
    # TODO [PAGE 03] - Select the school you teach at
    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

    # [PAGE 05] - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.has_entire_term_contract).to eql true

    # [PAGE 06] - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "Yes, I'm employed by my school"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_directly).to eql true

    # [PAGE 07] - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))

    choose "No"
    click_on "Continue"
  end
end
