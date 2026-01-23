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

  shared_examples "a task with notes section" do |task_name:|
    scenario "task notes section is displayed" do
      visit admin_claim_task_path(claim, name: task_name)

      expect(page).to have_content("Task notes")
      expect(page).to have_field("Add a note to this task")
    end

    scenario "adding a note to the task" do
      visit admin_claim_task_path(claim, name: task_name)

      fill_in "Add a note to this task", with: "Test note for #{task_name}"
      click_on "Add note"

      note = claim.notes.last
      expect(note.body).to eq("Test note for #{task_name}")
      expect(note.label).to eq(task_name)
      expect(page).to have_content("Test note for #{task_name}")
    end
  end

  context "alternative_identity_verification task" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        identity_confirmed_with_onelogin: false,
        academic_year: AcademicYear.new(2024)
      )
    end

    before do
      create(
        :further_education_payments_eligibility,
        claim: claim,
        provider_verification_email_last_sent_at: 1.day.ago,
        provider_verification_email_count: 1
      )
    end

    it_behaves_like "a task with notes section", task_name: "alternative_identity_verification"
  end

  context "ey_alternative_verification task" do
    let(:claim) { create(:claim, :submitted, policy: Policies::EarlyYearsPayments) }

    before do
      create(:early_years_payments_eligibility, :eligible, claim: claim)
      create(
        :task,
        :passed,
        name: "ey_alternative_verification",
        claim: claim,
        data: {"personal_details_match" => true, "bank_details_match" => true}
      )
    end

    it_behaves_like "a task with notes section", task_name: "ey_alternative_verification"
  end

  context "fe_alternative_verification task" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        academic_year: AcademicYear.new(2025)
      )
    end

    before do
      create(:further_education_payments_eligibility, claim: claim, flagged_as_duplicate: true)
      create(
        :task,
        :passed,
        name: "fe_alternative_verification",
        claim: claim,
        data: {"personal_details_match" => true, "bank_details_match" => true}
      )
    end

    it_behaves_like "a task with notes section", task_name: "fe_alternative_verification"
  end

  context "induction_confirmation task" do
    let(:claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }

    before do
      create(:task, name: "induction_confirmation", claim: claim, passed: true, manual: true)
    end

    it_behaves_like "a task with notes section", task_name: "induction_confirmation"
  end

  context "provider_details task" do
    let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments) }

    before do
      create(:further_education_payments_eligibility, claim: claim)
      create(:task, name: "provider_details", claim: claim, passed: true, manual: true)
    end

    it_behaves_like "a task with notes section", task_name: "provider_details"
  end
end
