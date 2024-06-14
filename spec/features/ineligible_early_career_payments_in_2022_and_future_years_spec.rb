require "rails_helper"

RSpec.feature "Ineligible Teacher Early-Career Payments claims by cohort" do
  include AdditionalPaymentsHelper

  [
    {
      policy_year: AcademicYear.new(2022),
      ineligible_cohorts: [
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2019)}
      ]
    },
    {
      policy_year: AcademicYear.new(2023),
      ineligible_cohorts: [
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2019)}
      ]
    }
  ].each do |policy|
    context "when accepting claims for AcademicYear #{policy[:policy_year]}" do
      before do
        create(:journey_configuration, :additional_payments, current_academic_year: policy[:policy_year])

        start_early_career_payments_claim

        journey_session.answers.assign_attributes(
          qualification: "postgraduate_itt"
        )
        journey_session.save!
      end

      let(:journey_session) do
        Journeys::AdditionalPaymentsForTeaching::Session.last
      end

      policy[:ineligible_cohorts].each do |scenario|
        scenario "with cohort ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]}" do
          jump_to_claim_journey_page(
            slug: "itt-year",
            journey_session: journey_session
          )

          # - In which academic year did you start your undergraduate ITT
          expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.#{journey_session.answers.qualification}"))
          choose scenario[:itt_academic_year].to_s(:long)
          click_on "Continue"

          expect(journey_session.reload.answers.itt_academic_year).to(
            eq(scenario[:itt_academic_year])
          )

          # - Which subject did you do your undergraduate ITT in
          expect(page).to have_text("Which subject")

          subject_name = scenario[:itt_subject].humanize

          if page.has_content?(subject_name)
            choose subject_name
            click_on "Continue"

            expect(journey_session.reload.answers.eligible_itt_subject).to eq scenario[:itt_subject]

            policy_checker = Policies::EarlyCareerPayments::PolicyEligibilityChecker.new(answers: journey_session.reload.answers)

            expect(policy_checker).to be_ineligible
          end
        end
      end
    end
  end
end
