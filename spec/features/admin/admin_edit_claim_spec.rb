require "rails_helper"

RSpec.feature "Admin edits a claim with an award amount" do
  let(:policy) { Policies::TargetedRetentionIncentivePayments }
  let(:signed_in_user_full_name) { @signed_in_user.full_name }

  let(:moment_of_submission) { 2.minutes.ago }
  let(:moment_of_submission_string) { I18n.l(moment_of_submission) }

  let(:old_award_amount) { 2_000 }

  let(:eligibility) do
    build(
      :"#{policy.to_s.underscore}_eligibility",
      :eligible,
      award_amount: old_award_amount
    )
  end

  let(:claim) do
    create(
      :claim,
      :submitted,
      policy: policy,
      eligibility: eligibility
    )
  end

  before do
    create(:journey_configuration, policy.locale_key)
    eligibility.update(eligible_degree_subject: false)
    @signed_in_user = sign_in_as_service_operator
  end

  context "non-claim attribute" do
    let(:old_value) { claim.eligibility.teacher_reference_number }
    let(:new_value) { old_value.next }
    let(:reason) { "Fix typo" }

    scenario "amend" do
      visit admin_claim_path(claim)

      click_on "Amend claim"

      fill_in "Teacher reference number", with: new_value
      fill_in "Change notes", with: reason

      travel_to(moment_of_submission) { click_on "Amend claim" }

      click_on "Claim amendments"

      expect(page).to have_content("Teacher reference number\nchanged from #{old_value} to #{new_value}")
      expect(page).to have_content(reason)
      expect(page).to have_content("by #{signed_in_user_full_name} on #{moment_of_submission_string}")
    end

    scenario "lacking reason" do
      visit admin_claim_path(claim)

      click_on "Amend claim"
      fill_in "Teacher reference number", with: new_value
      click_on "Amend claim"

      expect(page).to have_content("Error: Enter a message to explain why you are making this amendment")
    end

    scenario "cancel" do
      visit admin_claim_path(claim)

      click_on "Amend claim"
      fill_in "Teacher reference number", with: new_value
      click_on "Cancel"

      expect(page).to have_no_content(new_value)
    end
  end

  context "claim attribute" do
    let(:old_value) { old_award_amount }
    let(:new_value) { old_value - 1 }
    let(:old_value_string) { old_value.to_fs(:currency) }
    let(:new_value_string) { new_value.to_fs(:currency) }
    let(:reason) { "Wrong amount" }

    scenario "amend" do
      visit admin_claim_path(claim)

      click_on "Amend claim"

      fill_in "Award amount", with: new_value
      fill_in "Change notes", with: reason

      travel_to(moment_of_submission) { click_on "Amend claim" }

      click_on "Claim amendments"

      expect(page).to have_content("Award amount\nchanged from #{old_value_string} to #{new_value_string}")
      expect(page).to have_content(reason)
      expect(page).to have_content("by #{signed_in_user_full_name} on #{moment_of_submission_string}")
    end

    scenario "lacking reason" do
      visit admin_claim_path(claim)

      click_on "Amend claim"
      fill_in "Award amount", with: new_value
      click_on "Amend claim"

      expect(page).to have_content("Error: Enter a message to explain why you are making this amendment")
    end

    scenario "cancel" do
      visit admin_claim_path(claim)

      click_on "Amend claim"
      fill_in "Award amount", with: new_value
      click_on "Cancel"

      expect(page).to have_no_content(new_value)
    end
  end
end
