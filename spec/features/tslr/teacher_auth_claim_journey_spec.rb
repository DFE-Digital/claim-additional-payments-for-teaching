require "rails_helper"

RSpec.describe "Student loans claim with Teacher Auth", feature_flag: [:student_loans_teacher_auth] do
  let(:qts_year) do
    AcademicYear.current.start_year - Policies::StudentLoans::ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR
  end

  let(:one_login_uid) { "urn:fdc:gov.uk:2022:student-loans-teacher" }

  let(:teacher_record_url) do
    "https://dqt-api.education.gov.uk/v3/persons/1234567?include=alerts"
  end

  before do
    OmniAuth.config.mock_auth[:teacher_student_loans] = OmniAuth::AuthHash.new(
      provider: "teacher_student_loans",
      extra: {
        raw_info: {
          sub: one_login_uid,
          trn: "1234567",
          email: "seymour.skinner@springfield-elementary.edu",
          verified_name: ["Seymour", "T", "Skinner"],
          verified_date_of_birth: "1980-01-01"
        }
      }
    )
  end

  after do
    OmniAuth.config.mock_auth.delete(:teacher_student_loans)
  end

  context "when QTS year is confirmed and a TPS school is found" do
    it "confirms, then changes, the NI number supplied by Teacher Auth" do
      journey_configuration = create(:journey_configuration, :student_loans)
      previous_academic_year = journey_configuration.current_academic_year - 1
      within_beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
      within_end_of_month = Date.new(previous_academic_year.start_year, 10, 31)

      school = create(
        :school,
        :student_loans_eligible,
        name: "Springfield Elementary"
      )

      create(
        :teachers_pensions_service,
        teacher_reference_number: "1234567",
        start_date: within_beginning_of_month,
        end_date: within_end_of_month,
        school_urn: school.establishment_number,
        la_urn: school.local_authority.code
      )

      create(
        :school,
        :student_loans_eligible,
        name: "Shelbyville Grammar"
      )

      visit landing_page_path(
        Journeys::TeacherStudentLoanReimbursement.routing_name
      )

      click_on "Start now"

      stub_teacher_record(nino: "AB123456C")
      sign_in_with_teacher_auth

      expect(page).to have_content("Is this your National Insurance number?")
      expect(page).to have_content("AB123456C")
      click_button "Continue"
      expect(page).to have_content(
        "Select yes if this is your National Insurance number"
      )
      choose "Yes"
      click_button "Continue"

      expect(page).to have_content(
        "Academic year you completed your Initial Teacher Training (ITT)"
      )
      expect(page).to have_content("Are these details correct?")
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text(
        StudentLoansHelper.tap { |m| m.extend(m) }.claim_school_question
      )
      choose "Springfield Elementary"
      click_button "Continue"

      expect(page).to have_content(
        "Which of the following subjects did you teach at Springfield Elementary"
      )
      check "Physics"
      click_button "Continue"

      expect(page).to have_content(
        "Are you still employed to teach at a school in England?"
      )
      choose "Yes, at another school"
      click_button "Continue"

      fill_in(
        "Which school are you currently employed to teach at",
        with: "Shelbyville Grammar"
      )
      click_button "Continue"
      choose "Shelbyville Grammar"
      click_button "Continue"

      expect(page).to have_content "Were you employed in a leadership position"
      choose "No"
      click_button "Continue"

      expect(page).to have_content(
        "You are eligible to claim back student loan repayments"
      )
      click_button "Continue"

      expect(page).to have_content("How we will use the information you provide")
      click_button "Continue"

      expect(page).to have_content("student loan repayment amount")
      click_button "Continue"

      expect(page).to have_content("What is your home address?")
      click_button "Enter your address manually"
      fill_in "House number or name", with: "Test house"
      fill_in "Building and street", with: "Test street"
      fill_in "Town or city", with: "Test town"
      fill_in "Postcode", with: "TE57 1NG"
      click_button "Continue"

      expect(page).to have_content(
        "Which email address should we use to contact you?"
      )
      choose "seymour.skinner@springfield-elementary.edu"
      click_button "Continue"

      expect(page).to have_content(
        "Would you like to provide your mobile number?"
      )
      choose "No"
      click_button "Continue"

      expect(page).to have_content(
        "Enter the bank account details your salary is paid into"
      )
      fill_in "Name on the account", with: "S Skinner"
      fill_in "Sort code", with: "000000"
      fill_in "Account number", with: "00000000"
      click_button "Continue"

      expect(page).to have_content(
        "How is your gender recorded on your school’s payroll system?"
      )
      choose "Male"
      click_button "Continue"

      expect(page).to have_content(
        "Check your answers before sending your application"
      )
      # Check we're not replying details from teacher auth as we don't allow
      # changing them
      expect(page).not_to have_content("Seymour T Skinner")
      expect(page).not_to have_link(href: /personal-details/)
      expect(page).not_to have_content("teacher reference number")
      expect(page).not_to have_link(href: /teacher-reference-number/)

      expect(page).to have_content("AB123456C")
      expect(page).to have_link(href: /confirm-national-insurance-number/)

      click_on "Change what is your national insurance number?", visible: :all
      expect(page).to have_content("Is this your National Insurance number?")
      expect(page).to have_checked_field("Yes")
      choose "No"
      fill_in "What is your National Insurance number?", with: "AB654321C"
      click_button "Continue"

      expect(page).to have_content("student loan repayment amount")
      click_button "Continue"

      expect(page).to have_content("Check your answers before sending your application")
      expect(page).to have_content("AB654321C")
      expect(page).not_to have_content("AB123456C")

      perform_enqueued_jobs do
        click_button "Confirm and send"
      end

      expect(page).to have_content "Claim submitted"

      match = page.text.match(/Your reference number (?<ref>.*)\n/)

      claim = Claim.find_by! reference: match[:ref]
      expect(claim.eligibility.teacher_auth_one_login_uid).to eq(one_login_uid)
      expect(claim.identity_confirmed_with_onelogin).to be(true)

      sign_in_as_service_admin

      visit admin_claim_tasks_path(claim)

      expect(page).to have_summary_item(key: "TRN", value: "1234567")
      expect(page).to have_summary_item(key: "NI number", value: "AB654321C")
      expect(page).to(
        have_summary_item(key: "Full name", value: "Seymour T Skinner")
      )
      expect(page).to(
        have_summary_item(key: "Date of birth", value: "1 January 1980")
      )
      expect(page).to(
        have_summary_item(
          key: "Email address",
          value: "seymour.skinner@springfield-elementary.edu"
        )
      )
      expect(page).to have_summary_item(
        key: "Claim route",
        value: "Signed in with teacher auth"
      )

      expect(task_status("Identity confirmation")).to eq "Partial match"
      expect(task_status("Qualifications")).to eq "Passed"

      click_on "Confirm the claimant made the claim"
      expect(page).not_to have_text("Name not matched:")
      expect(page).not_to have_text("Date of birth not matched:")
      expect(page).to have_text("National insurance number not matched:")
      expect(page).to have_text('Claimant: "AB654321C"')
      expect(page).to have_text('Teacher Auth: "AB123456C"')

      click_on "Qualifications"
      expect(page).to have_text "Qualifications"

      within ".hmcts-timeline" do
        expect(page).to have_text "QTS award date: #{qts_year}-09-01"
      end
    end

    it "asks for the missing NI number and uses the other Teacher Auth details" do
      journey_configuration = create(:journey_configuration, :student_loans)
      previous_academic_year = journey_configuration.current_academic_year - 1
      within_beginning_of_month = Date.new(previous_academic_year.start_year, 10, 1)
      within_end_of_month = Date.new(previous_academic_year.start_year, 10, 31)

      school = create(
        :school,
        :student_loans_eligible,
        name: "Springfield Elementary"
      )

      create(
        :teachers_pensions_service,
        teacher_reference_number: "1234567",
        start_date: within_beginning_of_month,
        end_date: within_end_of_month,
        school_urn: school.establishment_number,
        la_urn: school.local_authority.code
      )

      create(
        :school,
        :student_loans_eligible,
        name: "Shelbyville Grammar"
      )

      visit landing_page_path(
        Journeys::TeacherStudentLoanReimbursement.routing_name
      )

      click_on "Start now"

      stub_teacher_record(
        nino: nil,
        alerts: [
          {
            startDate: "2026-09-01",
            endDate: nil
          }
        ]
      )
      sign_in_with_teacher_auth

      expect(page).to have_content("Enter your National Insurance number")
      expect(page).not_to have_field("First name")
      expect(page).not_to have_field("Last name")
      expect(page).not_to have_field("Day")
      click_button "Continue"

      expect(page).to have_content("Enter a National Insurance number in the correct format")
      fill_in "Enter your National Insurance number", with: "AB123456C"
      click_button "Continue"

      expect(page).to have_content(
        "Academic year you completed your Initial Teacher Training (ITT)"
      )
      expect(page).to have_content("Are these details correct?")
      choose "Yes"
      click_button "Continue"

      expect(page).to have_text(
        StudentLoansHelper.tap { |m| m.extend(m) }.claim_school_question
      )
      choose "Springfield Elementary"
      click_button "Continue"

      expect(page).to have_content(
        "Which of the following subjects did you teach at Springfield Elementary"
      )
      check "Physics"
      click_button "Continue"

      expect(page).to have_content(
        "Are you still employed to teach at a school in England?"
      )
      choose "Yes, at another school"
      click_button "Continue"

      fill_in(
        "Which school are you currently employed to teach at",
        with: "Shelbyville Grammar"
      )
      click_button "Continue"
      choose "Shelbyville Grammar"
      click_button "Continue"

      expect(page).to have_content "Were you employed in a leadership position"
      choose "No"
      click_button "Continue"

      expect(page).to have_content(
        "You are eligible to claim back student loan repayments"
      )
      click_button "Continue"

      expect(page).to have_content("How we will use the information you provide")
      click_button "Continue"

      expect(page).to have_content("student loan repayment amount")
      click_button "Continue"

      expect(page).to have_content("What is your home address?")
      click_button "Enter your address manually"
      fill_in "House number or name", with: "Test house"
      fill_in "Building and street", with: "Test street"
      fill_in "Town or city", with: "Test town"
      fill_in "Postcode", with: "TE57 1NG"
      click_button "Continue"

      expect(page).to have_content(
        "Which email address should we use to contact you?"
      )
      choose "seymour.skinner@springfield-elementary.edu"
      click_button "Continue"

      expect(page).to have_content(
        "Would you like to provide your mobile number?"
      )
      choose "No"
      click_button "Continue"

      expect(page).to have_content(
        "Enter the bank account details your salary is paid into"
      )
      fill_in "Name on the account", with: "S Skinner"
      fill_in "Sort code", with: "000000"
      fill_in "Account number", with: "00000000"
      click_button "Continue"

      expect(page).to have_content(
        "How is your gender recorded on your school’s payroll system?"
      )
      choose "Male"
      click_button "Continue"

      # Check we're not replying details from teacher auth as we don't allow
      # changing them
      expect(page).to have_content(
        "Check your answers before sending your application"
      )
      expect(page).not_to have_content("Seymour T Skinner")
      expect(page).not_to have_link(href: /personal-details/)
      expect(page).not_to have_content("teacher reference number")
      expect(page).not_to have_link(href: /teacher-reference-number/)
      expect(page).to have_link(href: %r{/national-insurance-number})
      expect(page).not_to have_link(href: /confirm-national-insurance-number/)

      click_on "Change what is your national insurance number?", visible: :all
      expect(page).to have_field(
        "Enter your National Insurance number",
        with: "AB123456C"
      )
      click_button "Continue"

      expect(page).to have_content(
        "Check your answers before sending your application"
      )

      perform_enqueued_jobs do
        click_button "Confirm and send"
      end

      expect(page).to have_content "Claim submitted"

      match = page.text.match(/Your reference number (?<ref>.*)\n/)

      claim = Claim.find_by! reference: match[:ref]
      expect(claim.eligibility.teacher_auth_one_login_uid).to eq(one_login_uid)
      expect(claim.identity_confirmed_with_onelogin).to be(true)

      sign_in_as_service_admin

      visit admin_claim_tasks_path(claim)

      expect(page).to have_summary_item(key: "TRN", value: "1234567")

      expect(page).to have_summary_item(key: "NI number", value: "AB123456C")

      expect(page).to(
        have_summary_item(key: "Full name", value: "Seymour T Skinner")
      )

      expect(page).to(
        have_summary_item(key: "Date of birth", value: "1 January 1980")
      )

      expect(page).to(
        have_summary_item(
          key: "Email address",
          value: "seymour.skinner@springfield-elementary.edu"
        )
      )

      expect(page).to have_summary_item(
        key: "Claim route",
        value: "Signed in with teacher auth"
      )

      expect(task_status("Identity confirmation")).to eq "Partial match"

      expect(task_status("Qualifications")).to eq "Passed"

      click_on "Confirm the claimant made the claim"
      expect(page).not_to have_text("Name not matched:")
      expect(page).not_to have_text("Date of birth not matched:")
      expect(page).to have_text("National insurance number not matched:")
      expect(page).to have_text("Teacher’s identity has an active alert")

      click_on "Qualifications"
      expect(page).to have_text "Qualifications"

      within ".hmcts-timeline" do
        expect(page).to have_text "QTS award date: #{qts_year}-09-01"
      end
    end
  end

  it "allows the claimant to retry a failed Teacher Auth sign-in" do
    OmniAuth.config.mock_auth[:teacher_student_loans] = :access_denied

    start_student_loans_journey

    click_button "Continue"

    expect(page).to have_text("Sorry, there is a problem with the service")
    click_link "Try again"
    expect(page).to have_text("Sign in with GOV.UK One Login")
  end

  it "asks the claimant for their QTS year when TRS has no QTS" do
    start_student_loans_journey

    stub_teacher_record(nino: "AB123456C", qts: nil)

    sign_in_with_teacher_auth

    expect(page).to have_content("Is this your National Insurance number?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text(
      I18n.t("student_loans.forms.qts_year.questions.qts_award_year")
    )
  end

  it "reports a failed teaching record lookup and asks for the QTS year" do
    start_student_loans_journey

    stub_request(:get, teacher_record_url).to_return(status: 503)

    expect(Sentry).to receive(:capture_exception).with(
      an_instance_of(Dqt::Error)
    )

    sign_in_with_teacher_auth

    expect(page).to have_content("Enter your National Insurance number")
    fill_in "Enter your National Insurance number", with: "AB123456C"
    click_button "Continue"

    expect(page).to have_text(
      I18n.t("student_loans.forms.qts_year.questions.qts_award_year")
    )
  end

  def start_student_loans_journey
    create(:journey_configuration, :student_loans)
    visit landing_page_path("student-loans")
    click_link "Start now"
  end

  def sign_in_with_teacher_auth
    perform_enqueued_jobs do
      click_button "Continue"
    end

    visit current_path
  end

  def stub_teacher_record(nino:, alerts: [], qts: {holdsFrom: "#{qts_year}-09-01"})
    stub_request(:get, teacher_record_url).to_return(
      status: 200,
      headers: {"Content-Type" => "application/json"},
      body: {
        trn: "1234567",
        nationalInsuranceNumber: nino,
        qts: qts,
        alerts: alerts
      }.to_json
    )
  end
end
