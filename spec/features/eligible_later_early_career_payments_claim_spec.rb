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
        {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020", award_amount: number_to_currency(7_500, precision: 0)},
        {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "Physics", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(3_000, precision: 0)},
        {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(3_000, precision: 0)}
      ].each do |scenario|
        scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
          claim.eligibility.public_send("itt_subject_#{scenario[:itt_subject].gsub(/\s/, "_").downcase}!")
          claim.eligibility.public_send("itt_academic_year_#{scenario[:itt_academic_year].gsub(/\s-\s/, "_")}!")

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

    context "without uplift school" do
      let(:current_school) { School.find(ActiveRecord::FixtureSet.identify(:hampstead_school, :uuid)) }

      [
        {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020", award_amount: number_to_currency(5_000, precision: 0)},
        {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "Physics", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(2_000, precision: 0)},
        {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021", award_amount: number_to_currency(2_000, precision: 0)}
      ].each do |scenario|
        scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} it displays award amount of #{scenario[:award_amount]}" do
          claim.eligibility.public_send("itt_subject_#{scenario[:itt_subject].gsub(/\s/, "_").downcase}!")
          claim.eligibility.public_send("itt_academic_year_#{scenario[:itt_academic_year].gsub(/\s-\s/, "_")}!")

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
