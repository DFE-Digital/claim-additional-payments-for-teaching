require "rails_helper"

RSpec.describe "Admin employment history task" do
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

  it "allows admins to remove employments" do
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
        employment_history: [
          {
            id: "1111-1111-1111-1111",
            school_id: school_1.id,
            employment_start_date: Date.new(2023, 5, 1),
            employment_end_date: Date.new(2024, 4, 1),
            subject_employed_to_teach: "physics",
            met_minimum_teaching_hours: true,
            created_by: create(:dfe_signin_user)
          },
          {
            id: "1111-1111-1111-1112",
            school_id: school_2.id,
            employment_start_date: Date.new(2024, 5, 1),
            employment_end_date: Date.new(2025, 4, 1),
            subject_employed_to_teach: "physics",
            met_minimum_teaching_hours: true,
            created_by: create(:dfe_signin_user)
          }
        ]
      }
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    within '[data-test-id="employment-1111-1111-1111-1111"]' do
      click_on "Remove employment"
    end

    expect(page).not_to have_text("Springfield Elementary School")

    expect(page).to have_text("Enriched Learning Center for Gifted Children")
  end

  it "doesn't allow completing the task until there is at least one employment" do
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

    expect(page).not_to have_text("Save and continue")

    expect(page).to have_text(
      "You can‘t check the claimant‘s employment until it has been uploaded"
    )
  end

  it "allows completing the task when there is at least one employment" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true,
        employment_history: [
          {
            id: "1111-1111-1111-1111",
            school: create(:school),
            employment_start_date: Date.new(2023, 5, 1),
            employment_end_date: Date.new(2024, 4, 1),
            subject_employed_to_teach: "physics",
            met_minimum_teaching_hours: true,
            created_by: create(:dfe_signin_user)
          }
        ]
      }
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    within '[data-test-id="task-form"]' do
      choose "Yes"
      click_on "Save and continue"
    end

    visit admin_claim_tasks_path(claim)

    expect(task_status("Employment history")).to eq("Passed")
  end

  it "doesn't allow adding or removing employment if the task is completed" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::InternationalRelocationPayments,
      eligibility_attributes: {
        changed_workplace_or_new_contract: true,
        employment_history: [
          {
            id: "1111-1111-1111-1111",
            school: create(:school),
            employment_start_date: Date.new(2023, 5, 1),
            employment_end_date: Date.new(2024, 4, 1),
            subject_employed_to_teach: "physics",
            met_minimum_teaching_hours: true,
            created_by: create(:dfe_signin_user)
          }
        ]
      }
    )

    create(:task, :passed, name: "employment_history", claim: claim)

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on "Check employment history"

    expect(page).not_to have_text("Add employment")
    expect(page).not_to have_text("Remove employment")
  end

  def select_from_autocomplete(label, value)
    fill_in label, with: value

    menu = nil

    Timeout.timeout(5) do
      until menu&.visible?
        menu = find("ul.autocomplete__menu")
        sleep 0.5
      end
    end

    within menu do
      option = find("li", text: value)

      Timeout.timeout(5) do
        while option.visible?
          option.click

          sleep 0.5
        end
      end
    end
  end
end
