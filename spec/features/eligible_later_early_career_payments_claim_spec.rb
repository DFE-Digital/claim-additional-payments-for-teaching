require "rails_helper"

RSpec.feature "Eligible later Teacher Early-Career Payments" do
  extend ActionView::Helpers::NumberHelper

  describe "claim" do
    let(:claim) do
      claim = start_early_career_payments_claim

      eligibility_attrs = attributes_for(:early_career_payments_eligibility, :eligible)
      eligibility_attrs[:current_school] = current_school
      claim.eligibility.update!(eligibility_attrs)

      claim
    end

    context "with uplift school" do
      let(:current_school) { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      [
        {
          policy_year: AcademicYear.new(2021),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(7_500, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0), next_eligible_year: AcademicYear.new(2022)}
          ]
        },
        {
          policy_year: AcademicYear.new(2022),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018), award_amount: number_to_currency(7_500, precision: 0), next_eligible_year: AcademicYear.new(2023)}
          ]
        },
        {
          policy_year: AcademicYear.new(2023),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(7_500, precision: 0), next_eligible_year: AcademicYear.new(2024)}
          ]
        }
      ].each do |policy_year|
        context "when accepting claims for AcademicYear #{policy_year[:policy_year]}" do
          before do
            @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
            PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: policy_year[:policy_year])
          end

          after do
            PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
          end

          policy_year[:eligible_later].each do |scenario|
            scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
              claim.eligibility.update(
                eligible_itt_subject: scenario[:itt_subject],
                itt_academic_year: scenario[:itt_academic_year]
              )

              visit claim_path(claim.policy.routing_name, "check-your-answers-part-one")

              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

              %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
                expect(page).not_to have_text section_heading
              end

              within(".govuk-summary-list") do
                expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
                expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
              end

              click_on("Continue")

              expect(page).to have_text("You will be eligible for a #{scenario[:award_amount]} early-career payment in #{scenario[:next_eligible_year].start_year}")
              expect(page).to have_text("you’ll be able to claim #{scenario[:award_amount]} in autumn #{scenario[:next_eligible_year].start_year}")
            end
          end
        end
      end
    end

    context "without uplift school" do
      let(:current_school) { School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid)) }
      [
        {
          policy_year: AcademicYear.new(2021),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(5_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0), next_eligible_year: AcademicYear.new(2022)},
            {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0), next_eligible_year: AcademicYear.new(2022)}
          ]
        },
        {
          policy_year: AcademicYear.new(2022),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018), award_amount: number_to_currency(5_000, precision: 0), next_eligible_year: AcademicYear.new(2023)}
          ]
        },
        {
          policy_year: AcademicYear.new(2023),
          eligible_later: [
            {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(5_000, precision: 0), next_eligible_year: AcademicYear.new(2024)}
          ]
        }
      ].each do |policy_year|
        context "when accepting claims for AcademicYear #{policy_year[:policy_year]}" do
          before do
            @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
            PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: policy_year[:policy_year])
          end

          after do
            PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
          end

          policy_year[:eligible_later].each do |scenario|
            scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
              claim.eligibility.update(
                eligible_itt_subject: scenario[:itt_subject],
                itt_academic_year: scenario[:itt_academic_year]
              )

              visit claim_path(claim.policy.routing_name, "check-your-answers-part-one")

              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
              expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

              %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
                expect(page).not_to have_text section_heading
              end

              within(".govuk-summary-list") do
                expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
                expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
              end

              click_on("Continue")

              expect(page).to have_text("You will be eligible for a #{scenario[:award_amount]} early-career payment in #{scenario[:next_eligible_year].start_year}")
              expect(page).to have_text("you’ll be able to claim #{scenario[:award_amount]} in autumn #{scenario[:next_eligible_year].start_year}")
            end
          end
        end
      end
    end
  end
end
