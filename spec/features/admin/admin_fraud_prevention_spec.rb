require "rails_helper"

RSpec.feature "Admin fraud prevention" do
  let(:fraud_risk_csv) do
    File.open(Rails.root.join("spec", "fixtures", "files", "fraud_risk.csv"))
  end

  before do
    sign_in_as_service_operator
  end

  context "when updating the list of flagged attributes" do
    it "flags any matching claims" do
      flagged_claim_trn = create(
        :claim,
        :submitted,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      flagged_claim_nino = create(
        :claim,
        :submitted,
        national_insurance_number: "QQ123456C"
      )

      flagged_claim_trn_and_nino = create(
        :claim,
        :submitted,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        },
        national_insurance_number: "QQ123456C"
      )

      visit new_admin_fraud_risk_csv_upload_path
      attach_file "Upload fraud risk CSV file", fraud_risk_csv.path
      click_on "Upload"

      expect(page).to have_content(
        "Fraud prevention list uploaded successfully."
      )

      visit admin_claim_tasks_path(flagged_claim_trn)

      expect(page).to have_content(
        "This claim has been flagged for fraud prevention as it has a " \
        "teacher reference number that is present in the fraud risk CSV."
      )

      visit admin_claim_tasks_path(flagged_claim_nino)

      expect(page).to have_content(
        "This claim has been flagged for fraud prevention as it has a " \
        "national insurance number that is present in the fraud risk CSV."
      )

      visit admin_claim_tasks_path(flagged_claim_trn_and_nino)

      expect(page).to have_content(
        "This claim has been flagged for fraud prevention as it has a " \
        "national insurance number and teacher reference number that is " \
        "present in the fraud risk CSV."
      )
    end
  end

  it "allows for downloading the csv" do
    visit new_admin_fraud_risk_csv_upload_path
    attach_file "Upload fraud risk CSV file", fraud_risk_csv.path
    click_on "Upload"

    click_on "Download"
    expect(page.body).to eq(fraud_risk_csv.read.chomp)
  end
end
