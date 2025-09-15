require "rails_helper"

RSpec.describe "Status and Processed by labels" do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:claim) do
    create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility, school: fe_provider))
  end

  scenario "Default status and processed_by labels when claim is submitted" do
    claim
    sign_in_to(fe_provider)

    expect(page).to have_content("Unverified claims")

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Status and processed_by change when verification starts" do
    provider_user = create(:dfe_signin_user,
      dfe_sign_in_id: "test-provider-123",
      given_name: "Test",
      family_name: "Provider",
      current_organisation_ukprn: fe_provider.ukprn,
      role_codes: ["teacher_payments_claim_verifier"])

    claim

    visit new_further_education_payments_providers_session_path
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: fe_provider.ukprn
    fill_in "DfE sign in UID", with: provider_user.dfe_sign_in_id
    fill_in "First name", with: provider_user.given_name
    fill_in "Last name", with: provider_user.family_name
    click_button "Start now"

    click_link claim.full_name

    choose "Yes"

    click_button "Continue"

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("In progress")
      expect(page).to have_content("Test Provider")
    end
  end

  scenario "Save and come back later changes status" do
    claim
    sign_in_to(fe_provider)

    click_link claim.full_name

    click_button "Save and come back later"

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("In progress")
    end
  end

  scenario "Back button does not change status" do
    claim
    sign_in_to(fe_provider)

    click_link claim.full_name

    choose "Yes"

    click_link "Back"

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Error message does not change status" do
    claim
    sign_in_to(fe_provider)

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
    create_list(:claim, 2, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_verification_started_at: nil))

    create_list(:claim, 3, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_verification_started_at: Time.current))

    other_provider = create(:school, :fe_eligible, ukprn: "87654321")
    create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: other_provider,
        provider_verification_started_at: nil))

    sign_in_to(fe_provider)

    within(".status-card--not-started") do
      expect(page).to have_content("2")
      expect(page).to have_content("Not started")
    end

    within(".status-card--in-progress") do
      expect(page).to have_content("3")
      expect(page).to have_content("In progress")
    end

    expect(page).to have_content("Unverified claims ( 5 )")

    expect(page).to have_selector("table tbody tr", count: 5)
  end

  scenario "Completed claims do not appear on unverified claims page" do
    completed_claim = create(:claim, :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_verification_started_at: 1.hour.ago,
        provider_verification_completed_at: Time.current))

    sign_in_to(fe_provider)

    expect(page).not_to have_content(completed_claim.full_name)
  end

  scenario "'Processed by' column displays correct provider name", js: true do
    provider_user = create(:dfe_signin_user,
      given_name: "Jane",
      family_name: "Doe",
      current_organisation_ukprn: fe_provider.ukprn,
      role_codes: ["teacher_payments_claim_verifier"])

    create(:claim, :submitted,
      first_name: "John",
      surname: "Smith",
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_assigned_to: nil))

    create(:claim, :submitted,
      first_name: "Mary",
      surname: "Jones",
      policy: Policies::FurtherEducationPayments,
      eligibility: build(:further_education_payments_eligibility,
        school: fe_provider,
        provider_assigned_to: provider_user,
        provider_verification_started_at: Time.current))

    sign_in_to(fe_provider)

    within("table tbody") do
      within("tr", text: "John Smith") do
        expect(page).to have_content("Not processed")
      end

      within("tr", text: "Mary Jones") do
        expect(page).to have_content("Jane Doe")
      end
    end
  end

  private

  def sign_in_to(fe_provider)
    visit new_further_education_payments_providers_session_path
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: fe_provider.ukprn
    click_button "Start now"
  end
end
