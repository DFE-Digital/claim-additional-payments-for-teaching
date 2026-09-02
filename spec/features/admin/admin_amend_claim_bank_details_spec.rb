require "rails_helper"

RSpec.feature "Admin amends a claims bank details",
  :with_hmrc_bank_validation_enabled,
  :with_stubbed_hmrc_client do
  let(:claim) do
    create(
      :claim,
      :submitted,
      banking_name: "Seymour Skinner",
      bank_sort_code: "010203",
      bank_account_number: "47274828"
    )
  end

  context "when bank details aren't changed" do
    it "doesn't show a banner or validate with hmrc" do
      sign_in_as_service_admin

      visit new_admin_claim_amendment_path(claim)

      fill_in "Email address", with: "seymoure.skinner"

      fill_in "Change notes", with: "Test"

      click_on "Amend claim"

      expect(page).not_to have_css(".govuk-notification-banner")
    end
  end

  context "when the bank details validate with hmrc" do
    let(:hmrc_bank_verification_response_body) do
      {
        sortCodeIsPresentOnEISCD: "yes",
        accountExists: "yes",
        nameMatches: "yes"
      }.to_json
    end

    it "shows the admin a success banner" do
      sign_in_as_service_admin

      visit new_admin_claim_amendment_path(claim)

      fill_in "Banking name", with: "Seymour T Skinner"

      fill_in "Change notes", with: "Test"

      click_on "Amend claim"

      expect(page).to have_css(".govuk-notification-banner")
      expect(page).to have_css(".govuk-notification-banner--success")

      expect(page).to have_content "Sort code: Yes - sort code found"

      expect(page).to have_content(
        "Account number: Yes - sort code and account number match"
      )

      expect(page).to have_content(
        "Yes - name matches the account holder name"
      )
    end
  end

  context "when the bank details partially match with hmrc" do
    let(:hmrc_bank_verification_response_body) do
      {
        sortCodeIsPresentOnEISCD: "yes",
        accountExists: "yes",
        nameMatches: "partial"
      }.to_json
    end

    it "shows the admin a partial match banner" do
      sign_in_as_service_admin

      visit new_admin_claim_amendment_path(claim)

      fill_in "Banking name", with: "Seymour T Skinner"

      fill_in "Change notes", with: "Test"

      click_on "Amend claim"

      expect(page).to have_css(".govuk-notification-banner")

      expect(page).to have_content "Sort code: Yes - sort code found"

      expect(page).to have_content(
        "Account number: Yes - sort code and account number match"
      )

      expect(page).to have_content(
        "Partial - name partially matches the account holder name"
      )
    end
  end

  context "when the bank details fail validation with hmrc" do
    let(:hmrc_bank_verification_response_body) do
      {
        sortCodeIsPresentOnEISCD: "yes",
        accountExists: "no",
        nameMatches: "no"
      }.to_json
    end

    it "shows the admin a failure banner" do
      sign_in_as_service_admin

      visit new_admin_claim_amendment_path(claim)

      fill_in "Banking name", with: "Seymour T Skinner"

      fill_in "Change notes", with: "Test"

      click_on "Amend claim"

      expect(page).to have_css(".govuk-notification-banner")

      expect(page).not_to have_css(".govuk-notification-banner--success")

      expect(page).to have_content "Sort code: Yes - sort code found"

      expect(page).to have_content(
        "Account number: No - sort code and account number do not match"
      )

      expect(page).to have_content(
        "No - name does not match the account holder name"
      )
    end
  end

  context "when the hmrc api returns an error", :with_hmrc_bank_validation_enabled, :with_failing_hmrc_bank_validation do
    it "shows the admin failure banner" do
      sign_in_as_service_admin

      visit new_admin_claim_amendment_path(claim)

      fill_in "Banking name", with: "Seymour T Skinner"

      fill_in "Change notes", with: "Test"

      click_on "Amend claim"

      expect(page).to have_css(".govuk-notification-banner")

      expect(page).not_to have_css(".govuk-notification-banner--success")

      expect(page).to have_content(
        "Sort code: Unknown - HMRC did not return an answer"
      )

      expect(page).to have_content(
        "Account number: Unknown - HMRC did not return an answer"
      )

      expect(page).to have_content(
        "Name on the account: Unknown - HMRC did not return an answer"
      )
    end
  end
end
