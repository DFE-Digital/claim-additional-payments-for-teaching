require "rails_helper"

RSpec.feature "Admin task list filtering" do
  scenario "filters claims by task statuses and assignee" do
    admin_alice = create(
      :dfe_signin_user,
      given_name: "Alice",
      family_name: "Anderson"
    )

    admin_bob = create(
      :dfe_signin_user,
      given_name: "Bob",
      family_name: "Baker"
    )

    claim_1 = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "CLAIM001",
      assigned_to: admin_alice
    )

    claim_2 = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "CLAIM002",
      assigned_to: admin_bob
    )

    claim_3 = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "CLAIM003"
    )

    # Claim 1: all tasks passed
    create(
      :task,
      name: "identity_confirmation",
      passed: true,
      manual: true,
      claim: claim_1
    )

    create(
      :task,
      name: "qualifications",
      passed: true,
      manual: true,
      claim: claim_1
    )

    create(
      :task,
      name: "census_subjects_taught",
      passed: true,
      manual: true,
      claim: claim_1
    )

    # Claim 2: all tasks failed
    create(
      :task,
      name: "identity_confirmation",
      passed: false,
      manual: true,
      claim: claim_2
    )

    create(
      :task,
      name: "qualifications",
      passed: false,
      manual: true,
      claim: claim_2
    )

    create(
      :task,
      name: "census_subjects_taught",
      passed: false,
      manual: true,
      claim: claim_2
    )

    # Claim 3: identity_confirmation and qualifications passed, census_subjects_taught failed
    create(
      :task,
      name: "identity_confirmation",
      passed: true,
      manual: true,
      claim: claim_3
    )

    create(
      :task,
      name: "qualifications",
      passed: true,
      manual: true,
      claim: claim_3
    )

    create(
      :task,
      name: "census_subjects_taught",
      passed: false,
      manual: true,
      claim: claim_3
    )

    sign_in_as_service_operator

    # Navigate directly to Student Loans policy with "All" assignee filter
    visit admin_task_lists_path

    click_on "Student Loans"

    # All claims should be visible initially (default shows all statuses)
    expect(page).to have_content("3 claims found")
    expect(page).to have_content("CLAIM001")
    expect(page).to have_content("CLAIM002")
    expect(page).to have_content("CLAIM003")

    click_on "Show filters"

    # Uncheck failed/incomplete for identity_confirmation and qualifications
    # This leaves only "Passed" for these two tasks, while keeping all statuses for other tasks
    within_fieldset "Identity confirmation" do
      uncheck "Failed"
      uncheck "Incomplete"
    end

    within_fieldset "Qualifications" do
      uncheck "Failed"
      uncheck "Incomplete"
    end

    click_on "Apply"

    # Claims 1 and 3 have passed identity_confirmation and qualifications
    expect(page).to have_content("CLAIM001")
    expect(page).to have_content("CLAIM003")
    expect(page).not_to have_content("CLAIM002")

    # Now check all and filter by assignee Bob Baker
    click_on "Check all"

    select "Bob Baker", from: "Assigned to"

    click_on "Apply"

    # Only claim 2 is assigned to Bob
    expect(page).to have_content("CLAIM002")
    expect(page).not_to have_content("CLAIM001")
    expect(page).not_to have_content("CLAIM003")
  end

  scenario "filters claims by employment match statuses" do
    claim_passed = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "EMPMATCH"
    )

    create(
      :task,
      name: "employment",
      claim: claim_passed,
      passed: true,
      claim_verifier_match: :all,
      manual: false
    )

    claim_no_match = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "EMPNONE"
    )

    create(
      :task, :claim_verifier_context,
      name: "employment",
      claim: claim_no_match,
      passed: nil,
      claim_verifier_match: :none,
      manual: false,
      created_by: nil
    )

    claim_no_data = create(
      :claim,
      :submitted,
      :current_academic_year,
      policy: Policies::StudentLoans,
      reference: "EMPNODAT"
    )

    create(
      :task, :claim_verifier_context,
      name: "employment",
      claim: claim_no_data,
      passed: nil,
      claim_verifier_match: nil,
      manual: false,
      created_by: nil
    )

    sign_in_as_service_operator

    visit admin_task_lists_path

    click_on "Student Loans"

    expect(page).to have_content("3 claims found")
    expect(page).to have_content("EMPMATCH")
    expect(page).to have_content("EMPNONE")
    expect(page).to have_content("EMPNODAT")

    click_on "Show filters"

    # Filter to only show "No match" employment tasks
    within_fieldset "Employment" do
      uncheck "Passed"
      uncheck "Failed"
      uncheck "No data"
      uncheck "Incomplete"
    end

    click_on "Apply"

    expect(page).to have_content("1 claims found")
    expect(page).to have_content("EMPNONE")
    expect(page).not_to have_content("EMPMATCH")
    expect(page).not_to have_content("EMPNODAT")

    # Filter to only show "No data" employment tasks
    within_fieldset "Employment" do
      uncheck "No match"
      check "No data"
    end

    click_on "Apply"

    expect(page).to have_content("1 claims found")
    expect(page).to have_content("EMPNODAT")
    expect(page).not_to have_content("EMPMATCH")
    expect(page).not_to have_content("EMPNONE")

    # Filter to only show "Passed" employment tasks
    within_fieldset "Employment" do
      uncheck "No data"
      check "Passed"
    end

    click_on "Apply"

    expect(page).to have_content("1 claims found")
    expect(page).to have_content("EMPMATCH")
    expect(page).not_to have_content("EMPNONE")
    expect(page).not_to have_content("EMPNODAT")
  end
end
