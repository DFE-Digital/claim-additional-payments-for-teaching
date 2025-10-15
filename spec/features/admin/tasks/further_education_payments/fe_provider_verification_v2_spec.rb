require "rails_helper"

RSpec.feature "Viewing the FE provider verification year 2 task" do
  before do
    sign_in_as_service_operator
  end

  context "when the provider hasn't completed the verification" do
    it "shows that the provider hasn't completed verification" do
      claim = create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        academic_year: AcademicYear.new("2025/2026"),
        eligibility: create(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verifiable
        )
      )

      # Create the task manually since provider verification isn't complete
      claim.tasks.create!(
        name: "fe_provider_verification_v2",
        passed: false,
        manual: true
      )

      visit admin_claim_tasks_path(claim)

      within(".fe_provider_verification_v2") do
        first("a").click
      end

      expect(page).to have_content("The provider has not completed this check yet.")

      expect(page).not_to have_content("Save and continue")
    end
  end

  context "when the provider has completed the verification" do
    it "shows the verification details" do
      claim = create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        academic_year: AcademicYear.new("2025/2026"),
        eligibility: create(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verification_completed,
          contract_type: "fixed_term",
          provider_verification_contract_type: "fixed_term",
          fixed_term_full_year: true,
          provider_verification_contract_covers_full_academic_year: true,
          teaching_responsibilities: true,
          provider_verification_teaching_responsibilities: true,
          further_education_teaching_start_year: "2023",
          provider_verification_teaching_start_year_matches_claim: true,
          teaching_hours_per_week: "more_than_12",
          provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week",
          half_teaching_hours: true,
          provider_verification_half_teaching_hours: true,
          provider_verification_half_timetabled_teaching_time: true,
          subjects_taught: %w[maths physics],
          maths_courses: %w[approved_level_321_maths],
          physics_courses: %w[alevel_physics],
          subject_to_formal_performance_action: false,
          provider_verification_performance_measures: false,
          subject_to_disciplinary_action: false,
          provider_verification_disciplinary_action: false,
          teaching_qualification: "yes",
          provider_verification_teaching_qualification: "yes"
        )
      )

      # Trigger the job to create the fe_provider_verification_v2 task
      Tasks::FeProviderVerificationV2Job.new.perform(claim)

      visit admin_claim_tasks_path(claim)

      within(".fe_provider_verification_v2") do
        first("a").click
      end

      # Year 2 ordering
      within_table_row("Teaching responsibilities") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Yes")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("First 5 years of teaching") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("2023/2024")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Teaching qualification") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Yes")
        expect(provider_answer).to have_content("Yes")
      end

      within_table_row("Contract of employment") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Fixed-term")
        expect(provider_answer).to have_content("Fixed-term")
      end

      within_table_row("Subject to performance measures") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("No")
        expect(provider_answer).to have_content("No")
      end

      within_table_row("Subject to disciplinary action") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("No")
        expect(provider_answer).to have_content("No")
      end

      within_table_row("Timetabled teaching hours") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("12 hours or more each week")
        expect(provider_answer).to have_content("12 or more hours per week, but fewer than 20")
      end

      within_table_row("Contract covers full academic year") do |claimant_answer, provider_answer|
        expect(claimant_answer).to have_content("Yes")
        expect(provider_answer).to have_content("Yes")
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
    end
  end

  def within_table_row(label, &block)
    within(first("th", exact_text: label).find(:xpath, "./..")) do
      claimant_answer = find("td:first-of-type")
      provider_answer = find("td:last-of-type")

      yield(claimant_answer, provider_answer)
    end
  end
end
