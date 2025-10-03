require "rails_helper"

RSpec.feature "Viewing the FE provider verification year 2 task" do
  before do
    sign_in_as_service_operator
  end

  context "when the provider hasn't completed the verification" do
    it "shows that the provider hasn't completed verification" do
      claim = create(
        :claim,
        :submittable,
        policy: Policies::FurtherEducationPayments,
        submitted_at: 1.day.ago,
        eligibility: create(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verifiable
        )
      )

      visit admin_claim_tasks_path(claim)

      click_on(
        "Confirm the provider has responded and verified the claimant’s information"
      )

      expect(page).to have_content("The provider has not completed this check yet.")

      expect(page).not_to have_content("Save and continue")
    end
  end

  context "when the provider has completed the verification" do
    it "shows the verification details" do
      claim = create(
        :claim,
        :submittable,
        policy: Policies::FurtherEducationPayments,
        submitted_at: 1.day.ago,
        eligibility: create(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verification_completed,
          contract_type: "fixed_term",
          provider_verification_contract_type: "fixed_term",
          teaching_responsibilities: true,
          provider_verification_teaching_responsibilities: true,
          further_education_teaching_start_year: "2023",
          provider_verification_teaching_start_year_matches_claim: true,
          teaching_hours_per_week: "more_than_12",
          provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week",
          half_teaching_hours: true,
          provider_verification_half_teaching_hours: true,
          subjects_taught: %w[maths physics],
          maths_courses: %w[approved_level_321_maths],
          physics_courses: %w[alevel_physics],
          subject_to_formal_performance_action: false,
          provider_verification_performance_measures: false,
          subject_to_disciplinary_action: false,
          provider_verification_disciplinary_action: false
        )
      )

      visit admin_claim_tasks_path(claim)

      click_on(
        "Confirm the provider has responded and verified the claimant’s information"
      )

      within_table_row("Contract of employment") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Fixed-term")
        expect(provider_answer).to have_content("Fixed-term")
      end

      within_table_row("Teaching responsibilities") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Yes")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("First 5 years of teaching") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("2023/2024")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Timetabled teaching hours") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("More than 12 hours per week")
        expect(provider_answer).to have_content("12 or more hours per week, but fewer than 20")
      end

      within_table_row("Age range taught") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Yes")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Subject") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Maths")
        expect(claimant_answer).to have_content("Physics")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Course") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content(
          "Qualifications approved for funding at level 3 and below"
        )
        expect(claimant_answer).to have_content("A or AS level physics")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Performance measures") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("No")
        expect(provider_answer).to have_content("No")
      end

      within_table_row("Disciplinary action") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("No")
        expect(provider_answer).to have_content("No")
      end
    end
  end

  def within_table_row(label, &block)
    within(first("tr", text: label)) do
      claimant_answer = find("td:first-of-type")
      provider_answer = find("td:last-of-type")

      yield(claimant_answer, provider_answer)
    end
  end
end
