require "rails_helper"

RSpec.feature "Eligible later Teacher Early-Career Payments claims" do
  include ActionView::Helpers::NumberHelper

  context "with eligible claim" do
    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim
    end

    [
      {itt_subject: "Mathematics", itt_academic_year: "2019 - 2020", base_amount: 5_000, uplift_amount: 7_500},
      {itt_subject: "Mathematics", itt_academic_year: "2020 - 2021", base_amount: 2_000, uplift_amount: 3_000},
      {itt_subject: "Physics", itt_academic_year: "2020 - 2021", base_amount: 2_000, uplift_amount: 3_000},
      {itt_subject: "Chemistry", itt_academic_year: "2020 - 2021", base_amount: 2_000, uplift_amount: 3_000},
      {itt_subject: "Foreign languages", itt_academic_year: "2020 - 2021", base_amount: 2_000, uplift_amount: 3_000}
    ].each do |scenario|
      scenario "with ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]}" do
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
          expect(page).not_to have_text(I18n.t("early_career_payments.questions.postgraduate_masters_loan"))
          expect(page).not_to have_text(I18n.t("early_career_payments.questions.postgraduate_doctoral_loan"))
        end

        click_on("Continue")

        expect(page).to have_text("You will be eligible for an early-career payment in 2022")
        expect(page).to have_text("you’ll be able to claim #{number_to_currency(scenario[:base_amount], precision: 0)}")
        expect(page).to have_text("This could increase to #{number_to_currency(scenario[:uplift_amount], precision: 0)}")
      end
    end
  end
end
