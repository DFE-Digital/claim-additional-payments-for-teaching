RSpec.shared_examples "Admin View Claim logged in with tid" do |policy|
  let(:academic_year) { AcademicYear.current }

  let!(:claim_logged_in_with_tid) {
    eligibility = create(:"#{policy.to_s.underscore}_eligibility", :eligible)
    create(
      :claim,
      :submitted,
      :logged_in_with_tid,
      policy: policy,
      eligibility: eligibility
    )
  }

  let!(:approved_paid_claim) {
    eligibility = create(:"#{policy.to_s.underscore}_eligibility", :eligible)
    create(
      :claim,
      :approved,
      policy: policy,
      eligibility: eligibility
    )
  }
  let!(:approved_awaiting_payroll_claim) {
    eligibility = create(:"#{policy.to_s.underscore}_eligibility", :eligible)
    create(
      :claim,
      :payrollable,
      policy: policy,
      eligibility: eligibility
    )
  }
  before do
    @signed_in_user = sign_in_as_service_operator

    payroll_run = PayrollRun.create!(created_by: @signed_in_user)
    PayrollRunJob.perform_now(payroll_run, [approved_paid_claim.id], [])

    # NOTE: mirror claims factory for academic_year attribute "hardcoding" of 2019
    current_academic_year =
      if [Policies::TargetedRetentionIncentivePayments].include?(policy)
        academic_year
      else
        AcademicYear.new(2019)
      end
    @within_academic_year = Time.zone.local(current_academic_year.start_year, 9, 1, 12)
  end

  scenario "#{policy} view claim logged in with tid" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      find("a[href='#{admin_claim_tasks_path(claim_logged_in_with_tid)}']").click

      expect(page).to have_content("Claim route")
      expect(page).to have_content("Signed in with DfE Identity")
    end
  end

  scenario "#{policy} filter approved awaiting payroll claims" do
    travel_to(@within_academic_year) do
      visit admin_claims_path

      select "Approved awaiting payroll", from: "Status"
      click_on "Apply filters"

      find("a[href='#{admin_claim_tasks_path(approved_awaiting_payroll_claim)}']").click

      expect(page).to have_content("Not signed in with DfE Identity")
    end
  end
end
