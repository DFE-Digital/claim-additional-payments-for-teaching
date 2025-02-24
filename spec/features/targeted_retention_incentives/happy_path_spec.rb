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
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
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

        # teaching-subject-now
        choose "Yes"
        click_on "Continue"

        expect(page).to have_content "Check your answers"

        expect(page).to have_summary_item(
          key: "Which school do you teach at?",
          value: school.name
        )

        expect(page).to have_summary_item(
          key: "Are you currently teaching as a qualified teacher?",
          value: "Yes"
        )

        expect(page).to have_summary_item(
          key: "Are you currently employed as a supply teacher?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Are you subject to any formal performance measures as a result " \
               "of continuous poor teaching standards?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Are you currently subject to disciplinary action?",
          value: "No"
        )

        expect(page).to have_summary_item(
          key: "Which route into teaching did you take?",
          value: "Postgraduate initial teacher training (ITT)"
        )

        expect(page).to have_summary_item(
          key: "In which academic year did you start your postgraduate initial "\
               "teacher training (ITT)?",
          value: "2023 to 2024"
        )

        expect(page).to have_summary_item(
          key: "Which subject did you do your postgraduate initial teacher " \
               "training (ITT) in?",
          value: "Physics"
        )

        expect(page).to have_summary_item(
          key: "Do you spend at least half of your contracted hours teaching " \
               "eligible subjects?",
          value: "Yes"
        )

        # Personal details and claim submission
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
