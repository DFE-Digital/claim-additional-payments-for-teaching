require "rails_helper"

RSpec.feature "Upload SLC data" do
  before do
    create(:journey_configuration, :student_loans) # used by StudentLoanAmountCheckJob
    create(:journey_configuration, :early_career_payments)
    create(:journey_configuration, :further_education_payments)
    create(:journey_configuration, :early_years_payment_provider_start)
    sign_in_as_service_operator
  end

  let!(:sl_claim_with_slc_data_no_student_loan) {
    create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: AcademicYear.current,
      eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 0),
      has_student_loan: false, student_loan_plan: "not_applicable", submitted_using_slc_data: false)
  }
  let!(:sl_claim_with_slc_data_with_student_loan) {
    create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: AcademicYear.current,
      eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 100),
      has_student_loan: true, student_loan_plan: "plan_1", submitted_using_slc_data: false)
  }
  let!(:sl_claim_no_slc_data) {
    create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: AcademicYear.current,
      eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 0),
      has_student_loan: false, student_loan_plan: "not_applicable", submitted_using_slc_data: false)
  }

  let!(:ecp_claim_with_slc_data_no_student_loan) {
    create(:claim, :submitted, policy: Policies::EarlyCareerPayments,
      eligibility: build(:early_career_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: false)
  }
  let!(:ecp_claim_with_slc_data_with_student_loan) {
    create(:claim, :submitted, policy: Policies::EarlyCareerPayments,
      eligibility: build(:early_career_payments_eligibility, :eligible),
      has_student_loan: true, student_loan_plan: "plan_1", submitted_using_slc_data: false)
  }
  let!(:ecp_claim_no_slc_data) {
    create(:claim, :submitted, policy: Policies::EarlyCareerPayments,
      eligibility: build(:early_career_payments_eligibility, :eligible),
      has_student_loan: false, student_loan_plan: "not_applicable", submitted_using_slc_data: false)
  }

  let!(:fe_claim_with_slc_data_no_student_loan_nil_submitted_using_slc_data) {
    create(:claim, :submitted, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: nil) # having nil submitted_using_slc_data won't happen after LUPEYALPHA-1010 merged
  }
  let!(:fe_claim_with_slc_data_with_student_loan_nil_submitted_using_slc_data) {
    create(:claim, :submitted, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: nil) # having nil submitted_using_slc_data won't happen after LUPEYALPHA-1010 merged
  }
  let!(:fe_claim_no_slc_data_nil_submitted_using_slc_data) {
    create(:claim, :submitted, :with_student_loan, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: nil) # having nil submitted_using_slc_data won't happen after LUPEYALPHA-1010 merged
  }
  let!(:fe_claim_with_slc_data_no_student_loan) {
    create(:claim, :submitted, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: false)
  }
  let!(:fe_claim_with_slc_data_with_student_loan) {
    create(:claim, :submitted, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: false)
  }
  let!(:fe_claim_no_slc_data) {
    create(:claim, :submitted, :with_student_loan, policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, :eligible),
      has_student_loan: nil, student_loan_plan: nil, submitted_using_slc_data: false)
  }

  scenario "automated task to verify student loan plan" do
    visit admin_claims_path
    click_link "Upload SLC data"
    attach_file "file", slc_data_csv_file.path
    perform_enqueued_jobs do
      click_button "Upload"
    end
    expect(page).to have_content "SLC file uploaded and queued to be imported"
    expect(StudentLoansData.count).to eq 8

    # Student Loans

    claim = sl_claim_with_slc_data_no_student_loan
    then_the_student_loan_amount_task_should_show_as(state: "No match", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "not_applicable"
    expect(claim.has_student_loan).to be false
    expect(claim.eligibility.student_loan_repayment_amount).to eq 0

    claim = sl_claim_with_slc_data_with_student_loan
    visit admin_claims_path
    click_link claim.reference
    then_the_student_loan_amount_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "plan_1"
    expect(claim.has_student_loan).to eq true
    expect(claim.eligibility.student_loan_repayment_amount).to eq 100

    claim = sl_claim_no_slc_data
    then_the_student_loan_amount_task_should_show_as(state: "No data", for_claim: claim)
    expect(claim.reload.student_loan_plan).to be nil
    expect(claim.has_student_loan).to be nil
    expect(claim.eligibility.student_loan_repayment_amount).to eq 0

    # Early Career Payments

    claim = ecp_claim_with_slc_data_no_student_loan
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "not_applicable"
    expect(claim.has_student_loan).to be false

    claim = ecp_claim_with_slc_data_with_student_loan
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "plan_1"
    expect(claim.has_student_loan).to eq true

    claim = ecp_claim_no_slc_data
    then_the_student_loan_plan_task_should_show_as(state: "Incomplete", for_claim: claim)
    expect(claim.reload.student_loan_plan).to be nil # this was "not_applicable" before LUPEYALPHA-1031
    expect(claim.has_student_loan).to be nil # this was false before LUPEYALPHA-1031

    # Further Education Payments

    claim = fe_claim_with_slc_data_no_student_loan_nil_submitted_using_slc_data
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "not_applicable"
    expect(claim.has_student_loan).to eq false

    claim = fe_claim_with_slc_data_with_student_loan_nil_submitted_using_slc_data
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "plan_1"
    expect(claim.has_student_loan).to eq true

    claim = fe_claim_no_slc_data_nil_submitted_using_slc_data
    then_the_student_loan_plan_task_should_show_as(state: "Incomplete", for_claim: claim)
    expect(claim.reload.student_loan_plan).to be nil
    expect(claim.has_student_loan).to be nil

    claim = fe_claim_with_slc_data_no_student_loan
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "not_applicable"
    expect(claim.has_student_loan).to eq false

    claim = fe_claim_with_slc_data_with_student_loan
    then_the_student_loan_plan_task_should_show_as(state: "Passed", for_claim: claim)
    expect(claim.reload.student_loan_plan).to eq "plan_1"
    expect(claim.has_student_loan).to eq true

    claim = fe_claim_no_slc_data
    then_the_student_loan_plan_task_should_show_as(state: "Incomplete", for_claim: claim)
    expect(claim.reload.student_loan_plan).to be nil
    expect(claim.has_student_loan).to be nil
  end

  def then_the_student_loan_amount_task_should_show_as(state:, for_claim:)
    visit admin_claims_path
    click_link for_claim.reference
    expect(page).to have_content "Student loan amount"
    within "li.student_loan_amount" do
      expect(page).to have_content state
    end
  end

  def then_the_student_loan_plan_task_should_show_as(state:, for_claim:)
    visit admin_claims_path
    click_link for_claim.reference
    expect(page).to have_content "Student loan plan"
    within "li.student_loan_plan" do
      expect(page).to have_content state
    end
  end

  def slc_data_csv_file
    return @slc_data_csv_file if @slc_data_csv_file

    @slc_data_csv_file = Tempfile.new
    @slc_data_csv_file.write StudentLoansDataImporter.mandatory_headers.join(",") + "\n"
    @slc_data_csv_file.write csv_row(sl_claim_with_slc_data_no_student_loan, no_data: true)
    @slc_data_csv_file.write csv_row(sl_claim_with_slc_data_with_student_loan, plan_type: "1", amount: "100")
    @slc_data_csv_file.write csv_row(ecp_claim_with_slc_data_no_student_loan, no_data: true)
    @slc_data_csv_file.write csv_row(ecp_claim_with_slc_data_with_student_loan, plan_type: "1", amount: "100")
    @slc_data_csv_file.write csv_row(fe_claim_with_slc_data_no_student_loan, no_data: true)
    @slc_data_csv_file.write csv_row(fe_claim_with_slc_data_with_student_loan, plan_type: "1", amount: "100")
    @slc_data_csv_file.write csv_row(fe_claim_with_slc_data_no_student_loan_nil_submitted_using_slc_data, no_data: true)
    @slc_data_csv_file.write csv_row(fe_claim_with_slc_data_with_student_loan_nil_submitted_using_slc_data, plan_type: "1", amount: "100")

    @slc_data_csv_file.rewind

    @slc_data_csv_file
  end

  def csv_row(claim, no_data: nil, plan_type: nil, amount: nil)
    values = [
      claim.reference,
      claim.national_insurance_number,
      "#{claim.first_name} #{claim.surname}",
      claim.date_of_birth.strftime(I18n.t("date.formats.day_month_year")),
      claim.policy.locale_key,
      "1",
      plan_type,
      amount
    ]
    values += if no_data
      ["No data", "No data", "No data"]
    else
      ["1", plan_type, amount]
    end
    values.join(",") << "\n"
  end
end
