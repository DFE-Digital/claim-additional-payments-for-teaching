require "rails_helper"

RSpec.describe "Targeted retention incentives" do
  before do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments
    )
  end

  context "happy path" do
    context "with DfE Identity" do
    end

    context "without DfE Identity" do
      it "allows the user to submit a claim" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all("input[type=radio][value='no']").each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        choose "2023 to 2024"
        click_on "Continue"

        # eligible-itt-subject
        choose "Physics"
        click_on "Continue"

        choose "Yes"
        click_on "Continue"

        expect(page).to have_content "Check your answers"
      end
    end

    context "When a supply teacher" do
      it "allows the user to sbumit a claim" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "Yes"
        click_on "Continue"

        # entire-term-contract
        choose "Yes"
        click_on "Continue"

        # employed-directly
        choose "Yes"
        click_on "Continue"

        # poor-performance
        all("input[type=radio][value='no']").each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        choose "2023 to 2024"
        click_on "Continue"

        # eligible-itt-subject
        choose "Physics"
        click_on "Continue"

        choose "Yes"
        click_on "Continue"

        expect(page).to have_content "Check your answers"
      end
    end
  end
end
