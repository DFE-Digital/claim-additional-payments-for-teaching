require "rails_helper"

RSpec.feature "Upload SLC data" do
  before do
    create(:journey_configuration, :student_loans) # used by StudentLoanAmountCheckJob
    create(:journey_configuration, :early_career_payments)
    create(:journey_configuration, :further_education_payments)
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
  let!(:fe_claim_no_student_loan_plan_no_slc_data) {
      create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: build(:further_education_payments_eligibility, :eligible), has_student_loan: nil, student_loan_plan: nil)
  }
  let!(:fe_claim_no_student_loan_plan_in_slc_data) {
      create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: build(:further_education_payments_eligibility, :eligible), has_student_loan: nil, student_loan_plan: nil)
  }
  let!(:fe_claim_not_in_data_file) {
      create(:claim, :submitted, :with_student_loan, policy: Policies::FurtherEducationPayments, eligibility: build(:further_education_payments_eligibility, :eligible))
  }

  scenario "automated task to verify student loan plan" do
    visit admin_claims_path
    click_link "Upload SLC data"
    attach_file "file", slc_data_csv_file.path
    perform_enqueued_jobs do
      click_button "Upload"
    end
    expect(page).to have_content "SLC file uploaded and queued to be imported"
    expect(StudentLoansData.count).to eq 4

    # Student Loans

    click_link sl_claim_with_slc_data_no_student_loan.reference
    expect(page).to have_content "Student loan amount"
    within "li.student_loan_amount" do
      expect(page).to have_content "No match"
    end
    expect(sl_claim_with_slc_data_no_student_loan.reload.student_loan_plan).to eq "not_applicable"
    expect(sl_claim_with_slc_data_no_student_loan.has_student_loan).to be false
    expect(sl_claim_with_slc_data_no_student_loan.eligibility.student_loan_repayment_amount).to eq 0

    visit admin_claims_path
    click_link ecp_claim_with_slc_data_with_student_loan.reference
    expect(page).not_to have_content "Student loan amount"
    expect(sl_claim_with_slc_data_with_student_loan.reload.student_loan_plan).to eq "plan_1"
    expect(sl_claim_with_slc_data_with_student_loan.has_student_loan).to eq true
    expect(sl_claim_with_slc_data_with_student_loan.eligibility.student_loan_repayment_amount).to eq 100

    visit admin_claims_path
    click_link sl_claim_no_slc_data.reference
    expect(page).to have_content "Student loan amount"
    within "li.student_loan_amount" do
      expect(page).to have_content "No data"
    end
    expect(sl_claim_no_slc_data.reload.student_loan_plan).to be nil
    expect(sl_claim_no_slc_data.has_student_loan).to be nil
    expect(sl_claim_no_slc_data.eligibility.student_loan_repayment_amount).to eq 0

    # Early Career Payments

    visit admin_claims_path
    click_link ecp_claim_with_slc_data_no_student_loan.reference
    expect(page).to have_content "Student loan plan"
    within "li.student_loan_plan" do
      expect(page).to have_content "Passed"
    end
    expect(ecp_claim_with_slc_data_no_student_loan.reload.student_loan_plan).to eq "not_applicable"
    expect(ecp_claim_with_slc_data_no_student_loan.has_student_loan).to be false

    visit admin_claims_path
    click_link ecp_claim_with_slc_data_with_student_loan.reference
    expect(page).to have_content "Student loan plan"
    within "li.student_loan_plan" do
      expect(page).to have_content "Passed"
    end
    expect(ecp_claim_with_slc_data_with_student_loan.reload.student_loan_plan).to eq "plan_1"
    expect(ecp_claim_with_slc_data_with_student_loan.has_student_loan).to eq true

    visit admin_claims_path
    click_link ecp_claim_no_slc_data.reference
    expect(page).to have_content "Student loan plan"
    within "li.student_loan_plan" do
      expect(page).to have_content "No data"
    end
    expect(ecp_claim_no_slc_data.reload.student_loan_plan).to be nil # this was "not_applicable" before LUPEYALPHA-1031
    expect(ecp_claim_no_slc_data.has_student_loan).to be nil # this was false before LUPEYALPHA-1031
    
    # FE
    
    visit admin_claims_path
    click_link fe_claim_no_student_loan_plan_no_slc_data.reference
    within "li.student_loan_plan" do
        expect(page).to have_content "Failed" # is this right?
    end
    expect(fe_claim_no_student_loan_plan_no_slc_data.reload.student_loan_plan).to eq "not_applicable"
    expect(fe_claim_no_student_loan_plan_no_slc_data.has_student_loan).to eq true # doesn't seem right - legacy attribute
    expect(fe_claim_no_student_loan_plan_no_slc_data.submitted_using_slc_data).to be false
    
    visit admin_claims_path
    click_link fe_claim_no_student_loan_plan_in_slc_data.reference
    within "li.student_loan_plan" do
        expect(page).to have_content "Passed"
    end
    expect(fe_claim_no_student_loan_plan_in_slc_data.reload.student_loan_plan).to eq "plan_1"
    expect(fe_claim_no_student_loan_plan_in_slc_data.has_student_loan).to eq true
    expect(fe_claim_no_student_loan_plan_in_slc_data.submitted_using_slc_data).to be false
    
    visit admin_claims_path
    click_link fe_claim_not_in_data_file.reference
    within "li.student_loan_plan" do
        expect(page).to have_content "No data"
    end
    expect(fe_claim_not_in_data_file.reload.student_loan_plan).to eq "not_applicable"
    expect(fe_claim_not_in_data_file.has_student_loan).to eq false
    expect(fe_claim_not_in_data_file.submitted_using_slc_data).to be false

  end

  def slc_data_csv_file
    return @slc_data_csv_file if @slc_data_csv_file

    @slc_data_csv_file = Tempfile.new
    @slc_data_csv_file.write StudentLoansDataImporter.mandatory_headers.join(",") + "\n"
    @slc_data_csv_file.write csv_row(sl_claim_with_slc_data_no_student_loan, no_data: true)
    @slc_data_csv_file.write csv_row(sl_claim_with_slc_data_with_student_loan, plan_type: "1", amount: "100")
    @slc_data_csv_file.write csv_row(ecp_claim_with_slc_data_no_student_loan, no_data: true)
    @slc_data_csv_file.write csv_row(ecp_claim_with_slc_data_with_student_loan, plan_type: "1", amount: "100")

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
