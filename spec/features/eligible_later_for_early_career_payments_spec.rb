require "rails_helper"

RSpec.feature "Teacher makes Early-Career Payments claim that is Eligible Later (2022)" do
  scenario "subject is 'mathematics' with 'route into teaching' set as '2018_2019'" do
    claim = start_early_career_payments_claim
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    claim.eligibility.itt_subject_mathematics!
    claim.eligibility.itt_academic_year_2018_2019!
    # claim.eligibility.public_send("itt_academic_year_#{route_into_teaching_year}!")

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

    expect(page).not_to have_text("You will be eligible for an early-career payment in 2022")
  end

  scenario "subject is 'mathematics' with 'route into teaching' set as '2019_2020'" do
    claim = start_early_career_payments_claim
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    claim.eligibility.itt_subject_mathematics!
    claim.eligibility.itt_academic_year_2019_2020!

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
    expect(page).to have_text("you’ll be able to claim £5,000")
    expect(page).to have_text("This could increase to £7,500")
  end

  scenario "subject is 'mathematics' with 'route into teaching' set as '2020_2021'" do
    claim = start_early_career_payments_claim
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    claim.eligibility.itt_subject_mathematics!
    claim.eligibility.itt_academic_year_2020_2021!

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
    expect(page).to have_text("you’ll be able to claim £2,000")
    expect(page).to have_text("This could increase to £3,000")
  end

  %w[chemistry foreign_languages physics].each do |subject|
    scenario "subject is '#{subject}' with 'route into teaching' set as '2020_2021'" do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.eligibility.public_send("itt_subject_#{subject}!")
      claim.eligibility.itt_academic_year_2020_2021!

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
      expect(page).to have_text("you’ll be able to claim £2,000")
      expect(page).to have_text("This could increase to £3,000")
    end
  end

  %w[chemistry foreign_languages physics].each do |subject|
    %w[2018_2019 2019_2020].each do |route_into_teaching_year|
      scenario "subject is '#{subject}' with 'route into teaching' set as '#{route_into_teaching_year}'" do
        claim = start_early_career_payments_claim
        claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
        claim.eligibility.public_send("itt_subject_#{subject}!")
        claim.eligibility.public_send("itt_academic_year_#{route_into_teaching_year}!")

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

        expect(page).not_to have_text("You will be eligible for an early-career payment in 2022")
      end
    end
  end
end
