require "rails_helper"

RSpec.describe "Admin first year payment task" do
  before do
    # Stub dqt api call in verifiers job
    dqt_teacher_resource = instance_double(Dqt::TeacherResource, find: nil)
    dqt_client = instance_double(Dqt::Client, teacher: dqt_teacher_resource)
    allow(Dqt::Client).to receive(:new).and_return(dqt_client)
  end

  context "when a first year claim is found" do
    it "creates the task" do
      first_year_claim = create(
        :claim,
        :submitted,
        :approved,
        policy: Policies::InternationalRelocationPayments,
        academic_year: AcademicYear.previous,
        national_insurance_number: "AB123456C"
      )

      create(:payment, claims: [first_year_claim])

      contract_start_date = AcademicYear.previous.start_of_autumn_term

      second_year_claim = create(
        :claim,
        :submitted,
        :approved,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C",
        eligibility_attributes: {
          current_school: create(:school),
          date_of_entry: contract_start_date - 1.week,
          start_date: contract_start_date
        }
      )

      ClaimVerifierJob.perform_now(second_year_claim)

      sign_in_as_service_operator

      visit admin_claim_tasks_path(second_year_claim)

      within ".app-task-list" do
        expect(page).to have_content("First year application")
      end

      click_on "Confirm this user has claimed their first year payment"

      expect(page).to have_text(first_year_claim.reference)

      expect(page).to have_text("Payrolled")

      choose "Yes"

      click_on "Save and continue"

      visit admin_claim_tasks_path(second_year_claim)

      expect(task_status("First year application")).to eq("Passed")
    end
  end

  context "when no first year claims are found" do
    it "creates the task" do
      contract_start_date = AcademicYear.previous.start_of_autumn_term

      claim = create(
        :claim,
        :submitted,
        :approved,
        policy: Policies::InternationalRelocationPayments,
        national_insurance_number: "AB123456C",
        eligibility_attributes: {
          current_school: create(:school),
          date_of_entry: contract_start_date - 1.week,
          start_date: contract_start_date
        }
      )

      ClaimVerifierJob.perform_now(claim)

      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)

      within ".app-task-list" do
        expect(page).to have_content("First year application")
      end

      click_on "Confirm this user has claimed their first year payment"

      expect(page).to have_content(
        "No previous claims from this claimant have been found that have " \
        "been approved or rejected"
      )

      choose "No"

      click_on "Save and continue"

      visit admin_claim_tasks_path(claim)

      expect(task_status("First year application")).to eq("Failed")
    end
  end
end
