require "rails_helper"

RSpec.feature "Admin of eligible EYTFI providers" do
  let(:eligible_eytfi_providers_csv_file) do
    file_fixture("eligible_eytfi_providers.csv")
  end

  scenario "manage eligible EYTFI providers" do
    when_eytfi_journey_configuration_exists
    sign_in_as_service_operator

    click_link "Manage services"
    click_link "Claim an early years teacher recognition payment"

    select AcademicYear.current.to_s, from: "Academic year"
    attach_file "eligible-eytfi-providers-upload-file-field", eligible_eytfi_providers_csv_file

    expect {
      click_button "Upload CSV"
    }.to change(FileUpload, :count).by(1)
      .and have_enqueued_job(EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob)

    file_upload = FileUpload.last

    expect(page.current_path).to eql(admin_file_upload_path(file_upload))
  end

  scenario "re-uploading the file doesn't lose existing claims" do
    academic_year = AcademicYear.current

    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      academic_year: academic_year
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    expect(page).to have_content(claim.reference)

    click_link "Manage services"
    click_link "Claim an early years teacher recognition payment"

    select academic_year.to_s, from: "Academic year"
    attach_file "eligible-eytfi-providers-upload-file-field", eligible_eytfi_providers_csv_file

    perform_enqueued_jobs do
      click_button "Upload CSV"
    end

    visit admin_claim_tasks_path(claim)

    expect(page).to have_content(claim.reference)
  end
end
