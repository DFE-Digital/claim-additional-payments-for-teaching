require "rails_helper"

RSpec.describe "TSLR claim with teacher auth by pass" do
  context "when QTS year is confirmed and a TPS school is found" do
    before do
      FeatureFlag.enable!(:student_loans_teacher_auth)
      allow(TeacherAuth::Config.instance).to receive(:bypass?) { true }

      stub_const(
        "Journeys::TeacherStudentLoanReimbursement::Debug::TeacherAuth::FetchQualificationsJob::JOB_SLEEP_SECONDS",
        0
      )

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
    end

    it "uses the details returned from teacher auth" do
      visit landing_page_path(
        Journeys::TeacherStudentLoanReimbursement.routing_name
      )

      click_on "Start now"

      fill_in "First name", with: "Seymour"
      fill_in "Middle name", with: "T"
      fill_in "Last name", with: "Skinner"

      within_fieldset "Date of Birth" do
        fill_in "Day", with: 1
        fill_in "Month", with: 1
        fill_in "Year", with: 1980
      end

      fill_in "National Insurance number", with: "AB123456C"

      fill_in "Email", with: "seymour.skinner@springfield-elementary.edu"

      fill_in "TRN", with: "1234567"

      qts_year = AcademicYear.current.start_year - Policies::StudentLoans::ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR

      within_fieldset "QTS award date" do
        fill_in "Day", with: 1
        fill_in "Month", with: 9
        fill_in "Year", with: qts_year
      end

      perform_enqueued_jobs do
        click_button "Continue"
      end

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
      click_on "Change what is your full name"

      expect(page).to have_text "Personal details"

      fill_in "First name", with: "Walter"
      fill_in "Middle name", with: "Seymour"
      fill_in "Last name", with: "Skinner"

      fill_in "What is your National Insurance number?", with: "AA123456C"

      click_button "Continue"

      # When personal details are changed we re check for student loan
      expect(page).to have_content("student loan repayment amount")
      click_button "Continue"

      perform_enqueued_jobs do
        click_button "Confirm and send"
      end

      expect(page).to have_content "Claim submitted"

      match = page.text.match(/Your reference number (?<ref>.*)\n/)

      claim = Claim.find_by! reference: match[:ref]

      sign_in_as_service_admin

      visit admin_claim_tasks_path(claim)

      expect(page).to have_summary_item(key: "TRN", value: "1234567")
      expect(page).to have_summary_item(key: "NI number", value: "AA123456C")
      expect(page).to(
        have_summary_item(key: "Full name", value: "Walter Seymour Skinner")
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
      expect(page).to have_text("[Teacher Auth Identity] - Name not matched:")
      expect(page).to have_text(
        'Claimant: "Walter Seymour Skinner" Teacher Auth: "Seymour Skinner"'
      )
      expect(page).to have_text(
        "[Teacher Auth Identity] - National insurance number not matched:"
      )
      expect(page).to have_text(
        'Claimant: "AA123456C" Teacher Auth: "AB123456C"'
      )
      # Date of birth wasn't changed from check answers page
      expect(page).not_to have_text(
        "[Teacher Auth Identity] - Date of birth not matched:"
      )

      choose "Yes"
      click_on "Save and continue"

      expect(page).to have_text "Qualifications"

      within ".hmcts-timeline" do
        expect(page).to have_text "QTS award date: #{qts_year}-09-01"
      end
    end
  end

  def task(name)
    page.find("h2", text: name).sibling("*").find("strong", class: ["app-task-list__task-completed"])
  end
end
