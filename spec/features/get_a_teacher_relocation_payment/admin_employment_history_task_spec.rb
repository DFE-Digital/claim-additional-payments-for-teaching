require "rails_helper"

RSpec.describe "Admin employment history task" do
  include GetATeacherRelocationPayment::StepHelpers

  before do
    create(:journey_configuration, :get_a_teacher_relocation_payment)

    # Stub the earliest eligible contract start date to a date in the past
    allow(
      Policies::InternationalRelocationPayments::PolicyEligibilityChecker
    ).to receive(:earliest_eligible_contract_start_date).and_return(
      Date.new(1970, 1, 1)
    )
  end

  context "when the claimant hasn't changed workplace" do
    it "doesn't create the employment history task" do
      claim = submit_irp_application(changed_work_place: false)

      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)

      within ".app-task-list" do
        expect(page).not_to have_content("Employment history")
      end
    end
  end

  context "when the claimant has changed workplace" do
    it "creates the employment history task" do
      claim = submit_irp_application(changed_work_place: true)

      sign_in_as_service_operator

      visit admin_claim_tasks_path(claim)

      within ".app-task-list" do
        expect(page).to have_content("Employment history")
      end
    end
  end

  it "allows admins to add multiple employments", js: true do
    create(:school, name: "Springfield Elementary School")

    create(:school, name: "Enriched Learning Center for Gifted Children")

    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true
      }
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    click_on "Add employment"

    fill_in "Previous workplace", with: "Springfield Elementary School"

    select_from_autocomplete(
      "Previous workplace",
      "Springfield Elementary School"
    )

    within '[data-test-id="employment-contract-of-at-least-one-year"]' do
      choose "Yes"
    end

    within '[data-test-id="employment-start-date"]' do
      fill_in "Day", with: "1"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2023"
    end

    within '[data-test-id="employment-end-date"]' do
      fill_in "Day", with: "1"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2024"
    end

    select "Physics", from: "Subject employed to teach"

    within '[data-test-id="met-minimum-teaching-hours"]' do
      choose "Yes"
    end

    click_on "Save and continue"

    click_on "Add employment"

    select_from_autocomplete(
      "Previous workplace",
      "Enriched Learning Center for Gifted Children"
    )

    within '[data-test-id="employment-contract-of-at-least-one-year"]' do
      choose "Yes"
    end

    within '[data-test-id="employment-start-date"]' do
      fill_in "Day", with: "1"
      fill_in "Month", with: "5"
      fill_in "Year", with: "2024"
    end

    within '[data-test-id="employment-end-date"]' do
      fill_in "Day", with: "1"
      fill_in "Month", with: "4"
      fill_in "Year", with: "2025"
    end

    select "Physics", from: "Subject employed to teach"

    within '[data-test-id="met-minimum-teaching-hours"]' do
      choose "Yes"
    end

    click_on "Save and continue"

    expect(page).to have_text("Springfield Elementary School")
    expect(page).to have_text("Enriched Learning Center for Gifted Children")
  end

  xit "allows admins to remove employments" do
    school_1 = create(:school, name: "Springfield Elementary School")

    school_2 = create(
      :school,
      name: "Enriched Learning Center for Gifted Children"
    )

    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true,
        employments: [
          {
            school_id: school_1.id,
            start_date: Date.new(2023, 5, 1),
            end_date: Date.new(2024, 4, 1),
            subject: "Physics",
            met_minimum_hours: true
          },
          {
            school_id: school_2.id,
            start_date: Date.new(2024, 5, 1),
            end_date: Date.new(2025, 4, 1),
            subject: "Physics",
            met_minimum_hours: true
          }
        ]
      }
    )

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    click_on "Remove employment"

    within "some-identifier" do
      check "Remove employment"
    end

    click_on "Remove employment"

    expect(page).not_to have_text("Springfield Elementary School")

    expect(page).to have_text("Enriched Learning Center for Gifted Children")
  end

  xit "doesn't allow completing the task until there is at least one employment" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true,
      }
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    expect(page).not_to have_text("Save and continue")

    expect(page).to have_text(
      "You can‘t check the claimant‘s employment until it has been uploaded"
    )
  end

  xit "doesn't allow adding or removing employment if the task is completed" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true,
        employments: [
          {
            school_id: create(:school).id,
            start_date: Date.new(2023, 5, 1),
            end_date: Date.new(2024, 4, 1),
            subject: "Physics",
            met_minimum_hours: true
          },
        ]
      }
    )

    create(:task, :passed, name: "employment_history", claim: claim)

    visit admin_claim_tasks_path(claim)

    click_on "Employment history"

    expect(page).not_to have_text("Add employment")
    expect(page).not_to have_text("Remove employment")
  end

  def submit_irp_application(changed_work_place:)
    school = create(:school)
    contract_start_date = AcademicYear.current.start_of_autumn_term
    entry_date = contract_start_date - 1.week

    when_i_start_the_form
    and_i_complete_application_route_question_with(
      option: "I am employed as a teacher in a school in England"
    )
    and_i_complete_the_state_funded_secondary_school_step_with(option: "Yes")
    and_i_complete_the_current_school_step(school)
    and_i_complete_the_headteacher_step
    and_i_complete_the_contract_details_step_with(option: "Yes")
    and_i_complete_the_contract_start_date_step_with(date: contract_start_date)
    and_i_complete_the_subject_step_with(option: "Physics")
    and_i_complete_changed_workplace_or_new_contract_with(
      option: changed_work_place ? "Yes" : "No"
    )
    and_i_complete_breaks_in_employment_with(option: "No")
    and_i_complete_the_visa_screen_with(option: "British National (Overseas) visa")
    and_i_complete_the_entry_date_page_with(date: entry_date)
    and_i_dont_change_my_answers
    and_i_complete_the_nationality_step_with(option: "Australian")
    and_i_complete_the_passport_number_step_with(options: "123456789")
    and_i_complete_the_personal_details_step(
      national_insurance_number: "QQ123456C"
    )
    and_i_complete_the_manual_address_step
    and_i_complete_the_email_address_step
    and_i_provide_my_mobile_number
    and_i_provide_my_personal_bank_details
    and_i_complete_the_payroll_gender_step
    and_i_submit_the_application

    Claim.by_policy(Policies::InternationalRelocationPayments).last
  end

  def select_from_autocomplete(label, value)
    fill_in label, with: value

    sleep(1)

    within "ul.autocomplete__menu" do
      option = find("li", text: value)

      Timeout.timeout(5) do
        while option.visible?
          option.click
        end
      end
    end
  end
end
