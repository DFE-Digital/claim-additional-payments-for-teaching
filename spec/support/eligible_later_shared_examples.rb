RSpec.shared_examples "Eligible later" do |opts|
  context "when accepting claims for AcademicYear #{opts[:policy_year]}" do
    let(:itt_academic_year) { opts[:itt_academic_year] }
    let(:next_eligible_year) { opts[:next_eligible_year] }
    let(:policy_year) { opts[:policy_year] }
    let(:qualification) { opts[:qualification] }
    let(:eligibility_attrs) { attributes_for(:early_career_payments_eligibility, :eligible).merge(current_school:) }
    let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: policy_year) }

    scenario "with ITT subject mathematics in ITT academic year #{opts[:itt_academic_year]} with a #{opts[:qualification]} qualification" do
      start_early_career_payments_claim

      journey_session.answers.assign_attributes(
        attributes_for(
          :additional_payments_answers,
          :submittable,
          itt_academic_year: itt_academic_year,
          eligible_itt_subject: itt_subject,
          qualification: qualification,
          current_school_id: current_school.id,
          nqt_in_academic_year_after_itt: true,
          induction_completed: true
        )
      )

      journey_session.save!

      jump_to_claim_journey_page(
        slug: "check-your-answers-part-one",
        journey_session: journey_session
      )

      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.primary_heading"))
      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.secondary_heading"))
      expect(page).to have_text(I18n.t("additional_payments.check_your_answers.part_one.confirmation_notice"))

      %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
        expect(page).not_to have_text section_heading
      end

      click_on("Continue")

      expect(page).to have_text("You could be eligible for an early-career payment next year")
      expect(page).to have_text("You are not eligible this year")

      if ["undergraduate_itt", "postgraduate_itt"].include?(qualification)
        match_text = qualification.split("_").first
        expect(page).to have_text(match_text)
      end

      if ["assessment_only", "overseas_recognition"].include?(qualification)
        expect(page).to have_text("qualified teacher status")
      end

      expect(page).to have_text("in the #{itt_academic_year.to_s(:long)}")

      expect(page).to have_text("You may be eligible next year")
      expect(page).to have_text("So long as your circumstances stay the same, you could claim for an early-career payment in the #{next_eligible_year.to_s(:long)} academic year.")

      expect(page).to have_text("Set a reminder to apply next year")
    end

    scenario "when induction was not completed" do
      start_early_career_payments_claim

      skip_tid

      # - Which school do you teach at
      expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))

      choose_school current_school

      # - Have you started your first year as a newly qualified teacher?
      expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

      choose "Yes"
      click_on "Continue"

      # - Have you completed your induction as an early-career teacher?
      expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))

      choose "No"
      click_on "Continue"

      expect(page).to have_text("You are not eligible for the early-career payment (opens in new tab) because you have not completed your induction.")
      expect(page).to have_text("You may be eligible next year")
      expect(page).to have_text("If you have completed your induction, you could claim for an early-career payment in the #{next_eligible_year.to_s(:long)} academic year.")

      expect(page).to have_text("Set a reminder to apply next year")
    end
  end
end
