require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  include StudentLoansHelper

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
  end

  let(:student_loans_school) { create(:school, :student_loans_eligible) }
  let(:ecp_school) { create(:school, :early_career_payments_eligible) }

  scenario "Teacher changes an answer which is not a dependency of any of the other answers they've given, remaining eligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))

    jump_to_claim_journey_page(claim, "check-your-answers")

    find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "subjects-taught")}']").click

    expect(find("#eligible_subjects_physics_taught").checked?).to eq(true)

    check "Biology"
    click_on "Continue"

    expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))

    expect(page).to have_text("Biology and Physics")

    expect(page).not_to have_text("Chemistry")
    expect(page).not_to have_text("Computing")
    expect(page).not_to have_text("Languages")
  end

  scenario "Teacher changes an answer which is not a dependency of any of the other answers they've given, becoming ineligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))
    jump_to_claim_journey_page(claim, "check-your-answers")

    find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "qts-year")}']").click

    expect(find("#claim_eligibility_attributes_qts_award_year_on_or_after_cut_off_date").checked?).to eq(true)

    choose_qts_year :before_cut_off_date
    click_on "Continue"

    expect(claim.eligibility.reload.qts_award_year).to eq("before_cut_off_date")

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training between the start of the #{Policies::StudentLoans.first_eligible_qts_award_year.to_s(:long)} academic year and the end of the 2020 to 2021 academic year.")
  end

  scenario "Teacher changes an answer which is a dependency of some of the subsequent answers they've given, remaining eligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))
    jump_to_claim_journey_page(claim, "check-your-answers")

    new_claim_school = create(:school, :student_loans_eligible, name: "Claim School")

    find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "claim-school")}']").click

    choose_school new_claim_school

    expect(claim.eligibility.reload.claim_school).to eql new_claim_school
    expect(claim.eligibility.physics_taught).to be_nil
    expect(claim.eligibility.biology_taught).to be_nil
    expect(claim.eligibility.employment_status).to be_nil
    expect(claim.eligibility.current_school).to be_nil

    expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "subjects-taught"))

    check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
    check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

    click_on "Continue"

    expect(claim.eligibility.reload.biology_taught).to eq(true)
    expect(claim.eligibility.chemistry_taught).to eq(true)

    expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "still-teaching"))

    choose_still_teaching "Yes, at Claim School"

    expect(claim.eligibility.reload.employment_status).to eql("claim_school")
    expect(claim.eligibility.current_school).to eql new_claim_school

    expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))
  end

  scenario "Teacher changes an answer which is a dependency of some of the subsequent answers they've given, making them ineligible" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, had_leadership_position: false, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))
    jump_to_claim_journey_page(claim, "check-your-answers")

    find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "leadership-position")}']").click

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.had_leadership_position).to eq(true)
    expect(claim.eligibility.mostly_performed_leadership_duties).to be_nil

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.mostly_performed_leadership_duties).to eq(true)

    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between #{Policies::StudentLoans.current_financial_year}.")
  end

  scenario "Teacher edits but does not change an answer which is a dependency of some of the subsequent answers they've given" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))

    jump_to_claim_journey_page(claim, "check-your-answers")

    find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "subjects-taught")}']").click

    expect(find("#eligible_subjects_physics_taught").checked?).to eq(true)

    click_on "Continue"

    expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))

    expect(page).to have_text("Physics")

    expect(page).not_to have_text("Biology")
    expect(page).not_to have_text("Chemistry")
    expect(page).not_to have_text("Computing")
    expect(page).not_to have_text("Languages")
  end

  scenario "when changing the student loan repayment amount the user can change answer and it preserves two decimal places" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 100.1, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))
    jump_to_claim_journey_page(claim, "check-your-answers")

    expect(page).to have_content("£100.10")
    first("a[href='#{claim_path(Policies::StudentLoans.routing_name, "student-loan-amount")}']").click

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
      eligibility.update!(attributes_for(:student_loans_eligibility, :eligible, current_school_id: student_loans_school.id, claim_school_id: student_loans_school.id))
      jump_to_claim_journey_page(claim, "check-your-answers")
    end

    scenario "Teacher can change a field that isn't related to eligibility" do
      old_number = claim.national_insurance_number
      new_number = "AB123456C"

      expect {
        page.first("a[href='#{claim_path(Policies::StudentLoans.routing_name, "personal-details")}']", minimum: 1).click
        fill_in "National Insurance number", with: new_number
        click_on "Continue"
      }.to change {
        claim.reload.national_insurance_number
      }.from(old_number).to(new_number)

      expect(page).to have_content("Check your answers before sending your application")
    end

    context "when changing student loan answer to “No” resets the other" do
      scenario "student loan and postgraduate masters/doctoral loan related answers" do
        jump_to_claim_journey_page(claim, "check-your-answers")

        find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "student-loan")}']").click

        choose "No"
        click_on "Continue"

        expect(claim.reload.has_student_loan).to eq false
        expect(claim.student_loan_country).to be_nil
        expect(claim.student_loan_courses).to be_nil
        expect(claim.student_loan_start_date).to be_nil
        expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "masters-doctoral-loan"))
        expect(page).to have_text(I18n.t("questions.has_masters_and_or_doctoral_loan"))

        choose "No"
        click_on "Continue"

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))
        expect(claim.reload.has_masters_doctoral_loan).to eq false
        expect(claim.postgraduate_masters_loan).to be_nil
        expect(claim.postgraduate_doctoral_loan).to be_nil
      end
    end

    context "when changing student loan answer to “Yes” resets the other" do
      scenario "student loan and postgraduate masters/doctoral loan related answers" do
        claim.update!(attributes_for(:claim, :submittable, :with_no_student_loan))
        jump_to_claim_journey_page(claim, "check-your-answers")

        find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "student-loan")}']").click

        choose "Yes"
        click_on "Continue"

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "student-loan-country"))
        expect(claim.reload.has_student_loan).to eq true
        expect(claim.student_loan_country).to be_nil
        expect(claim.student_loan_courses).to be_nil
        expect(claim.student_loan_start_date).to be_nil
        expect(claim.student_loan_plan).to be_nil
        expect(claim.eligibility.reload.student_loan_repayment_amount).to eql(1000.00)
        expect(claim.reload.has_masters_doctoral_loan).to be_nil
        expect(claim.postgraduate_masters_loan).to be_nil
        expect(claim.postgraduate_doctoral_loan).to be_nil
      end

      scenario "answer student loan and postgraduate masters/doctoral loans" do
        claim.update!(attributes_for(:claim, :submittable, :with_no_student_loan, :with_no_postgraduate_masters_doctoral_loan))
        jump_to_claim_journey_page(claim, "check-your-answers")

        find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "student-loan")}']").click

        choose "Yes"
        click_on "Continue"

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "student-loan-country"))
        expect(claim.reload.has_student_loan).to eq true
        expect(claim.student_loan_country).to be_nil
        expect(claim.student_loan_courses).to be_nil
        expect(claim.student_loan_start_date).to be_nil
        expect(claim.student_loan_plan).to be_nil

        expect(page).to have_text(I18n.t("questions.student_loan_country"))

        choose "Northern Ireland"
        click_on "Continue"

        expect(claim.reload.student_loan_country).to eql StudentLoan::NORTHERN_IRELAND
        expect(claim.student_loan_courses).to be_nil
        expect(claim.student_loan_start_date).to be_nil
        expect(claim.student_loan_plan).to eq StudentLoan::PLAN_1

        expect(current_path).not_to eq(claim_path(Policies::StudentLoans.routing_name, "masters-doctoral-loan"))
        expect(page).not_to have_text(I18n.t("questions.has_masters_and_or_doctoral_loan"))
        expect(claim.reload.has_masters_doctoral_loan).to be_nil

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "masters-loan"))
        expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

        choose "Yes"
        click_on "Continue"

        expect(claim.reload.postgraduate_masters_loan).to eq true

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "doctoral-loan"))
        expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

        choose "No"
        click_on "Continue"

        expect(claim.reload.postgraduate_doctoral_loan).to eq false

        expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))
      end
    end

    scenario "changing student loan country forces dependent questions to be re-answered" do
      claim.update!(attributes_for(:claim, :submittable, :with_no_postgraduate_masters_doctoral_loan))
      jump_to_claim_journey_page(claim, "check-your-answers")

      find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "student-loan-country")}']").click

      choose "Wales"
      click_on "Continue"

      choose "1"
      click_on "Continue"

      choose "Before 1 September 2012"
      click_on "Continue"

      expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))
      expect(claim.reload.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq StudentLoan::WALES
      expect(claim.student_loan_courses).to eq "one_course"
      expect(claim.student_loan_start_date).to eq StudentLoan::BEFORE_1_SEPT_2012
      expect(claim.student_loan_plan).to eq StudentLoan::PLAN_1
    end

    scenario "user can change the answer to identity details" do
      claim.update!(govuk_verify_fields: [])
      jump_to_claim_journey_page(claim, "check-your-answers")

      expect(page).to have_content(I18n.t("questions.name"))
      expect(page).to have_content(I18n.t("questions.address.generic.title"))
      expect(page).to have_content(I18n.t("questions.date_of_birth"))
      expect(page).to have_content(I18n.t("questions.payroll_gender"))
      expect(page).to have_selector(:css, "a[href='#{claim_path(Policies::StudentLoans.routing_name, "personal-details")}']")
      expect(page).to have_selector(:css, "a[href='#{claim_path(Policies::StudentLoans.routing_name, "address")}']")
      expect(page).to have_selector(:css, "a[href='#{claim_path(Policies::StudentLoans.routing_name, "gender")}']")

      page.first("a[href='#{claim_path(Policies::StudentLoans.routing_name, "personal-details")}']", minimum: 1).click
      fill_in "First name", with: "Bobby"
      click_on "Continue"

      expect(current_path).to eq(claim_path(Policies::StudentLoans.routing_name, "check-your-answers"))
      expect(claim.reload.first_name).to eq("Bobby")
    end

    scenario "user can change the answer to payment details" do
      jump_to_claim_journey_page(claim, "check-your-answers")

      expect(page).to have_content(I18n.t("questions.bank_or_building_society"))
      expect(page).to have_content("Personal bank account")

      find("a[href='#{claim_path(Policies::StudentLoans.routing_name, "bank-or-building-society")}']").click

      choose "Building society"
      click_on "Continue"

      expect(page).to have_content(I18n.t("questions.account_details", bank_or_building_society: claim.reload.bank_or_building_society.humanize.downcase))
      expect(page).to have_content("Building society roll number")

      expect(claim.bank_or_building_society).to eq :building_society.to_s
      expect(claim.banking_name).to be_nil
      expect(claim.bank_sort_code).to be_nil
      expect(claim.bank_account_number).to be_nil

      fill_in "Name on your account", with: "Miss Jasmine Aniski"
      fill_in "Sort code", with: "80-78-01"
      fill_in "Account number", with: "43290701"
      fill_in "Building society roll number", with: "6284/000390713"

      click_on "Continue"

      expect(claim.reload.banking_name).to eq "Miss Jasmine Aniski"
      expect(claim.bank_sort_code).to eq "807801"
      expect(claim.bank_account_number).to eq "43290701"
      expect(claim.building_society_roll_number).to eq "6284/000390713"
    end
  end

  describe "Teacher changes a field that requires OTP validation" do
    let!(:claim) { start_early_career_payments_claim }
    let(:eligibility) { claim.eligibility }

    before do
      claim.update!(attributes_for(:claim, :submittable))
      eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible, current_school_id: ecp_school.id))
      claim.update!(personal_details_attributes)

      jump_to_claim_journey_page(claim, "check-your-answers")
    end

    context "when email address" do
      let(:personal_details_attributes) { {} }

      scenario "is asked to provide the OTP challenge code for validation" do
        old_email = claim.email_address
        new_email = "fiona.adouboux@protonmail.com"

        expect {
          page.first("a[href='#{claim_path(Policies::EarlyCareerPayments.routing_name, "email-address")}']", minimum: 1).click
          fill_in "Email address", with: new_email
          click_on "Continue"
        }.to change {
          claim.reload.email_address
        }.from(old_email).to(new_email)

        expect(page).not_to have_content("Check your answers before sending your application")
        expect(page).to have_content("Email address verification")

        mail = ActionMailer::Base.deliveries.last
        otp_in_mail_sent = mail[:personalisation].decoded.scan(/\b[0-9]{6}\b/).first

        fill_in "claim_one_time_password", with: otp_in_mail_sent
        click_on "Confirm"

        expect(claim.reload.email_verified).to eq true
        expect(claim.submittable?).to be true
        expect(page).to have_content("Check your answers before sending your application")
      end
    end

    context "with no mobile number" do
      before do
        allow(NotifySmsMessage).to receive(:new).with(
          phone_number: new_mobile,
          template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
          personalisation: {
            otp: otp_code
          }
        ).and_return(notify)
        allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: otp_code))
        allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
      end

      let(:otp_code) { "019121" }
      let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }
      let(:personal_details_attributes) do
        {
          provide_mobile_number: false
        }
      end
      let(:new_mobile) { "07475112801" }

      scenario "is asked to provide the OTP challenge code for validation" do
        expect {
          page.first("a[href='#{claim_path(Policies::EarlyCareerPayments.routing_name, "provide-mobile-number")}']", minimum: 1).click
          choose "Yes"
          click_on "Continue"
        }.to change {
          claim.reload.provide_mobile_number
        }.from(false).to(true)

        expect(page).not_to have_content("Check your answers before sending your application")
        expect(page).to have_text(I18n.t("questions.mobile_number"))

        fill_in "claim_mobile_number", with: new_mobile
        click_on "Continue"

        expect(claim.reload.mobile_number).to eql new_mobile

        # - Mobile number one-time password
        expect(page).to have_text("Mobile number verification")
        expect(page).to have_text("Enter the 6-digit passcode")

        fill_in "claim_one_time_password", with: otp_code
        click_on "Confirm"

        expect(page).not_to have_text("Some places are both a bank and a building society")
        expect(claim.reload.mobile_verified).to eq true
        expect(claim.submittable?).to be true
        expect(page).to have_content("Check your answers before sending your application")
      end
    end

    context "with an existing mobile number" do
      before do
        allow(NotifySmsMessage).to receive(:new).with(
          phone_number: new_mobile,
          template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
          personalisation: {
            otp: otp_code
          }
        ).and_return(notify)
        allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: otp_code))
        allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
      end

      let(:otp_code) { "229213" }
      let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }
      let(:personal_details_attributes) do
        {
          provide_mobile_number: true,
          mobile_number: old_mobile,
          mobile_verified: true
        }
      end
      let(:new_mobile) { "07475112801" }
      let(:old_mobile) { "07813090710" }

      scenario "is asked to provide the OTP challenge code for validation" do
        old_mobile = claim.mobile_number

        expect {
          page.first("a[href='#{claim_path(Policies::EarlyCareerPayments.routing_name, "mobile-number")}']", minimum: 1).click
          fill_in "Mobile number", with: new_mobile
          click_on "Continue"
        }.to change {
          claim.reload.mobile_number
        }.from(old_mobile).to(new_mobile)

        expect(page).not_to have_content("Check your answers before sending your application")

        # - Mobile number one-time password
        expect(page).to have_text("Mobile number verification")
        expect(page).to have_text("Enter the 6-digit passcode")

        fill_in "claim_one_time_password", with: otp_code
        click_on "Confirm"

        expect(page).not_to have_text("Some places are both a bank and a building society")
        expect(claim.reload.mobile_verified).to eq true
        expect(claim.submittable?).to be true
        expect(page).to have_content("Check your answers before sending your application")
      end
    end
  end
end
