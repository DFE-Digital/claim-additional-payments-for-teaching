RSpec.shared_examples "Admin View Claim Feature" do |policy|
  let!(:claim) {
    create(
      :claim,
      :submitted,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  let!(:multiple_claim) {
    create(
      :claim,
      :submitted,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  let!(:similar_claim) {
    create(
      :claim,
      :submitted,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible),
      teacher_reference_number: multiple_claim.teacher_reference_number
    )
  }

  let!(:approved_awaiting_payroll_claim) {
    create(
      :claim,
      :payrollable,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  let!(:approved_paid_claim) {
    create(
      :claim,
      :approved,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  let!(:rejected_claim) {
    create(
      :claim,
      :rejected,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  before do
    @signed_in_user = sign_in_as_service_operator

    PayrollRun.create_with_claims!([approved_paid_claim], created_by: @signed_in_user)

    # NOTE: mirror claims factory for academic_year attribute "hardcoding" of 2019
    current_academic_year =
      if policy == EarlyCareerPayments
        PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      else
        AcademicYear.new(2019)
      end
    @within_academic_year = Time.zone.local(current_academic_year.start_year, 9, 1)
  end

  scenario "#{policy} filter approved awaiting payroll claims" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      select "Approved awaiting payroll", from: "Status"
      click_on "Go"

      find("a[href='#{admin_claim_tasks_path(approved_awaiting_payroll_claim)}']").click

      expect(page).to have_content("– Approved")
      expect(page).to have_content("Approved awaiting payroll")
    end
  end

  scenario "#{policy} filter approved claims" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      select "Approved", from: "Status"
      click_on "Go"

      find("a[href='#{admin_claim_tasks_path(approved_paid_claim)}']").click

      expect(page).to have_content("– Approved")
    end
  end

  scenario "#{policy} filter rejected claims" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      select "Rejected", from: "Status"
      click_on "Go"

      find("a[href='#{admin_claim_tasks_path(rejected_claim)}']").click

      expect(page).to have_content("– Rejected")
    end
  end

  scenario "#{policy} view full claim details from index" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      find("a[href='#{admin_claim_tasks_path(claim)}']").click

      expect(page).to have_content(policy.short_name)

      expect_page_to_have_policy_sections policy

      click_on "View full claim"
      expect(page).to have_content(policy.short_name)
    end
  end

  scenario "#{policy} has multiple claims" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      find("a[href='#{admin_claim_tasks_path(multiple_claim)}']").click

      expect(page).to have_content("Multiple claims with matching details have been made in this claim window.")
    end
  end

  def expect_page_to_have_policy_sections(policy)
    sections = case policy
    when StudentLoans
      ["Identity confirmation", "Qualifications", "Census subjects taught", "Employment", "Student loan amount", "Decision"]
    when MathsAndPhysics
      ["Identity confirmation", "Qualifications", "Employment", "Decision"]
    else
      ["Identity confirmation", "Qualifications", "Census subjects taught", "Employment", "Decision"]
    end

    sections.each_with_index do |title, i|
      expect(page).to have_content("#{i + 1}. #{title}")
    end

    expect(page).to have_no_content("#{sections.count + 1}. ")
  end
end
