require "rails_helper"

RSpec.feature "Combined claim journey dependent answers" do
  before { create(:journey_configuration, :targeted_retention_incentive_payments) }
  let!(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }

  scenario "Dependent answers reset" do
    visit new_claim_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME)

    # - Check eligibility intro
    expect(page).to have_text("Check you’re elegible for a targeted retention incentive payment")
    click_on "Start eligibility check"

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text("Are you currently teaching as a qualified teacher?")
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text("Are you currently employed as a supply teacher?")
    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text("Are you subject to any formal performance measures as a result of continuous poor teaching standards?")
    expect(page).to have_text("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text("Which route into teaching did you take?")
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you complete your postgraduate ITT?
    expect(page).to have_text("In which academic year did you start your postgraduate initial teacher training (ITT)?")
    choose "2020 to 2021"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
    choose "Yes"
    click_on "Continue"

    # User goes back in the journey and changes their answer to a question which resets other dependent answers
    visit claim_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME, "qualification")
    expect(page).to have_text("Which route into teaching did you take?")
    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    choose "2020 to 2021"
    click_on "Continue"

    # User should be redirected to the next question which was previously answered but wiped by the attribute dependency
    expect(page).to have_text("Which subject")

    # User tries to skip ahead and not answer the question
    visit claim_path(Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME, "teaching-subject-now")

    # User should be redirected to the dependent question still unanswered
    expect(page).to have_text("Which subject")
  end
end
