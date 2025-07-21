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

  scenario "Default status and processed_by labels when claim is submitted" do
    sign_in_to(fe_provider)

    expect(page).to have_content("Unverified claims")

    within("table") do
      expect(page).to have_content("Not started")
      expect(page).to have_content("Not processed")
    end
  end

  scenario "Status and processed_by change when verification starts" do
    sign_in_to(fe_provider)

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
    sign_in_to(fe_provider)

    click_link claim.full_name

    click_button "Save and come back later"

    visit further_education_payments_providers_claims_path

    within("table") do
      expect(page).to have_content("In progress")
    end
  end

  scenario "Back button does not change status" do
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
        expect(page).to have_content("Unassigned")
      end

      within("tr", text: "Mary Jones") do
        expect(page).to have_content("Jane Doe")
      end
    end
  end

  private

  def sign_in_to(fe_provider)
    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
      user_type: "provider"
    )

    visit new_further_education_payments_providers_session_path

    click_on "Start now"
  end
end
