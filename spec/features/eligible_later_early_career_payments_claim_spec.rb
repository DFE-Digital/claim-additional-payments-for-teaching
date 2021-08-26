require "rails_helper"

RSpec.feature "Eligible later Teacher Early-Career Payments claims" do
  extend ActionView::Helpers::NumberHelper

  context "with eligible later claim" do
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
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(7_500, precision: 0)},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(3_000, precision: 0)}
      ].each do |scenario|
        scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
          Timecop.freeze(Date.new(2021,9,1)) do
            claim.eligibility.update(
              eligible_itt_subject: scenario[:itt_subject],
              itt_academic_year: scenario[:itt_academic_year]
            )
  
            visit claim_path(claim.policy.routing_name, "check-your-answers-part-one")
  
            # [PAGE - Check your answers for eligibility]
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
  
            expect(page).to have_text("You will be eligible for an early-career payment in 2022")
            expect(page).to have_text("you’ll be able to claim #{scenario[:award_amount]} in autumn 2022")
          end
        end
      end
    end

    context "without uplift school" do
      let(:current_school) { School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid)) }

      [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), award_amount: number_to_currency(5_000, precision: 0)},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), award_amount: number_to_currency(2_000, precision: 0)}
      ].each do |scenario|
        scenario "with ITT subject #{scenario[:itt_subject].humanize} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
          Timecop.freeze(Date.new(2021,9,1)) do
            claim.eligibility.update(
            eligible_itt_subject: scenario[:itt_subject],
            itt_academic_year: scenario[:itt_academic_year]
          )

          visit claim_path(claim.policy.routing_name, "check-your-answers-part-one")

          # [PAGE - Check your answers for eligibility]
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

          expect(page).to have_text("You will be eligible for an early-career payment in 2022")
          expect(page).to have_text("you’ll be able to claim #{scenario[:award_amount]} in autumn 2022")
          end
        end
      end
    end
  end
end
