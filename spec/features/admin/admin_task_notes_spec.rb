require "rails_helper"

RSpec.feature "Admin task notes" do
  before do
    create(:journey_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "the service operator adds a note to a completed task" do
    claim = create(:claim, :submitted)
    create(:task, name: "employment", claim: claim, passed: true, manual: true)

    visit admin_claim_task_path(claim, name: "employment")

    expect(page).to have_content("Task notes")

    fill_in "Add a note to this task", with: "Verified employment manually via phone call"
    expect { click_on "Add note" }.to change { claim.notes.count }.by(1)

    note = claim.notes.last
    expect(note.body).to eq("Verified employment manually via phone call")
    expect(note.created_by).to eq(@signed_in_user)
    expect(note.label).to eq("employment")

    expect(page).to have_current_path(admin_claim_task_path(claim, name: "employment"))
    expect(page).to have_content("Verified employment manually via phone call")
  end

  scenario "task note is displayed on the Notes and support tab with task label" do
    claim = create(:claim, :submitted)
    create(:task, name: "employment", claim: claim, passed: true, manual: true)
    create(:note, claim: claim, label: "employment", body: "Task-specific note for employment")

    visit admin_claim_notes_path(claim)

    expect(page).to have_content("Task: Employment")
    expect(page).to have_content("Task-specific note for employment")

    # Task name links to the task detail page
    expect(page).to have_link("Employment", href: admin_claim_task_path(claim, name: "employment"))
    click_link "Employment"
    expect(page).to have_current_path(admin_claim_task_path(claim, name: "employment"))
  end

  scenario "with validation error when note body is blank" do
    claim = create(:claim, :submitted)
    create(:task, name: "employment", claim: claim, passed: true, manual: true)

    visit admin_claim_task_path(claim, name: "employment")

    fill_in "Add a note to this task", with: ""
    expect { click_on "Add note" }.not_to change { claim.notes.count }

    expect(page).to have_current_path(admin_claim_task_path(claim, name: "employment"))
    expect(page).to have_content("Enter a note")
  end

  scenario "existing task notes are displayed on the task page" do
    claim = create(:claim, :submitted)
    create(:task, name: "employment", claim: claim, passed: true, manual: true)
    task_note = create(:note, claim: claim, label: "employment", body: "Previous note about this task")

    visit admin_claim_task_path(claim, name: "employment")

    expect(page).to have_content("Task notes")
    expect(page).to have_content("Previous note about this task")
    expect(page).to have_content(task_note.created_by.full_name)
  end
end
