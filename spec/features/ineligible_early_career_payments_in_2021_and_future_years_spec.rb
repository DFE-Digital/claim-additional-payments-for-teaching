require "rails_helper"

RSpec.feature "Ineligible Teacher Early-Career Payments claims by cohort" do
  [
    {
      policy_year: AcademicYear.new(2021),
      ineligible_cohorts: [
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2018)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2019)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2019)}
      ]
    },
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
    },
    {
      policy_year: AcademicYear.new(2024),
      ineligible_cohorts: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018)}
      ]
    }
  ].each do |policy|
    context "when accepting claims for AcademicYear #{policy[:policy_year]}" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: policy[:policy_year])
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end

      let(:claim) do
        claim = start_early_career_payments_claim

        eligibility_attrs = attributes_for(:early_career_payments_eligibility, :ineligible_feature)
        claim.eligibility.update!(eligibility_attrs)

        claim
      end

      policy[:ineligible_cohorts].each do |scenario|
        scenario "with cohort ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]}" do
          visit claim_path(claim.policy.routing_name, "itt-year")

          # - In what academic year did you start your undergraduate ITT
          expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
          choose scenario[:itt_academic_year].to_s(:long)
          click_on "Continue"

          expect(claim.eligibility.reload.itt_academic_year).to eql scenario[:itt_academic_year]

          # - Which subject did you do your undergraduate ITT in
          expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

          choose scenario[:itt_subject].humanize
          click_on "Continue"

          expect(claim.eligibility.reload.eligible_itt_subject).to eq scenario[:itt_subject]

          expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
          expect(page).to have_link(href: "#{EarlyCareerPayments.eligibility_page_url}#eligibility-criteria")
          expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")

          expect(page).not_to have_text("You will be eligible for a ")
          expect(page).not_to have_text("you’ll be able to claim")
        end
      end
    end
  end
end
