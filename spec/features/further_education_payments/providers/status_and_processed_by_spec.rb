require "rails_helper"

RSpec.describe "Status and Processed by labels", feature_flag: :provider_dashboard do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:claim) do
    create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, school: fe_provider))
  end

  before do
    FeatureFlag.enable!(:provider_dashboard)
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "Default status and processed_by labels when claim is submitted" do
    sign_in_as_provider

    expect(page).to have_content("Unverified claims")

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Status and processed_by change when verification starts" do
    sign_in_as_provider

    click_link claim.full_name

    choose "Yes"

    click_button "Continue"

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("In progress")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Save and come back later changes status" do
    sign_in_as_provider

    click_link claim.full_name

    click_button "Save and come back later"

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("In progress")
    end
  end

  scenario "Back button does not change status" do
    sign_in_as_provider

    click_link claim.full_name

    choose "Yes"

    click_link "Back"

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Error message does not change status" do
    sign_in_as_provider

    click_link claim.full_name

    click_button "Continue"

    expect(page).to have_content("There is a problem")

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Claim count cards show correct values" do
    create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_verification_started_at: Time.current))

    create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider))

    sign_in_as_provider

    within(".govuk-grid-row") do
      expect(page).to have_content("2")
      expect(page).to have_content("1")
    end
  end

  scenario "Completed claims do not appear on unverified claims page" do
    completed_claim = create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_verification_started_at: 1.hour.ago,
        provider_verification_completed_at: Time.current))

    sign_in_as_provider

    expect(page).not_to have_content(completed_claim.full_name)
  end

  private

  def sign_in_as_provider
    visit "/further-education-payments/providers/claims"

    if page.has_button?("Accept additional cookies", wait: 1)
      click_button "Accept additional cookies"
      click_button "Hide cookie message" if page.has_button?("Hide cookie message", wait: 1)
    end

    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: fe_provider.ukprn
    click_button "Start now"

    expect(page).to have_current_path("/further-education-payments/providers/claims")
  end
end
