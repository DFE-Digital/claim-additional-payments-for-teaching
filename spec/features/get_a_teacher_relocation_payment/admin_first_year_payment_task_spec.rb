require "rails_helper"

RSpec.describe "Admin first year payment task" do
  include GetATeacherRelocationPayment::StepHelpers

  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)

    # Stub dqt api call in verifiers job
    dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
    dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
    allow(Dqt::Client).to receive(:new).and_return(dqt_client)

    # Stub the earliest eligible contract start date to a date in the past
    allow(
      Policies::InternationalRelocationPayments::PolicyEligibilityChecker
    ).to receive(:earliest_eligible_contract_start_date).and_return(
      Date.new(1970, 1, 1)
    )
  end

  context "when a first year claim is found" do
    it "creates the task" do
      school = create(:school)

      first_year_claim = create(
        :claim,
        :submitted,
        :approved,
        policy: Policies::InternationalRelocationPayments,
        academic_year: AcademicYear.previous,
        national_insurance_number: "QQ123456C"
      )

      create(:payment, claims: [first_year_claim])

      second_year_claim = submit_irp_application(
        school: school,
        contract_start_date: AcademicYear.previous.start_of_autumn_term,
        national_insurance_number: "QQ123456C"
      )

      perform_enqueued_jobs

      sign_in_as_service_operator

      visit admin_claim_tasks_path(second_year_claim)

      within ".app-task-list" do
        expect(page).to have_content("First year payment")
      end

      click_on "Confirm this user has claimed their first year payment"

      expect(page).to have_text(first_year_claim.reference)

      expect(page).to have_text("Payrolled")

      choose "Yes"

      click_on "Save and continue"

      visit admin_claim_tasks_path(second_year_claim)

      expect(task_status("First year payment")).to eq("Passed")
    end
  end

  context "when no first year claims are found" do
    it "creates the task" do
      claim = submit_irp_application(
        school: create(:school),
        contract_start_date: AcademicYear.previous.start_of_autumn_term,
        national_insurance_number: "QQ123456C"
      )

      perform_enqueued_jobs

      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)

      within ".app-task-list" do
        expect(page).to have_content("First year payment")
      end

      click_on "Confirm this user has claimed their first year payment"

      expect(page).to have_content(
        "No previous claims from this claimant have been found that have " \
        "been approved or rejected"
      )

      choose "No"

      click_on "Save and continue"

      visit admin_claim_tasks_path(claim)

      expect(task_status("First year payment")).to eq("Failed")
    end
  end

  def submit_irp_application(school:, national_insurance_number:, contract_start_date:)
    entry_date = contract_start_date - 1.week

    when_i_start_the_form
    and_i_complete_the_previous_irp_payment_question_with(option: "Yes")
    and_i_complete_application_route_question_with(
      option: "I am employed as a teacher in a school in England"
    )
    and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
    and_i_complete_the_current_school_step(school)
    and_i_complete_the_headteacher_step
    and_i_complete_the_contract_details_step_with(option: "Yes")
    and_i_complete_the_contract_start_date_step_with(date: contract_start_date)
    and_i_complete_the_subject_step_with(option: "Physics")
    and_i_complete_changed_workplace_or_new_contract_with(option: "No")
    and_i_complete_breaks_in_employment_with(option: "No")
    and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
    and_i_complete_the_entry_date_page_with(date: entry_date)
    and_i_dont_change_my_answers
    and_i_complete_the_nationality_step_with(option: "Australian")
    and_i_complete_the_passport_number_step_with(options: "123456789")
    and_i_complete_the_personal_details_step(
      national_insurance_number: national_insurance_number
    )
    and_i_complete_the_manual_address_step
    and_i_complete_the_email_address_step
    and_i_provide_my_mobile_number
    and_i_provide_my_personal_bank_details
    and_i_complete_the_payroll_gender_step
    and_i_submit_the_application

    Claim.by_policy(Policies::InternationalRelocationPayments).last
  end
end
