require "rails_helper"

RSpec.feature "Ineligible Teacher Early-Career Payments claims" do
  context "when PolicyConfiguration current_academic_year is NOT 2021" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "NQT not in Academic Year after ITT" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

      choose "No"
      click_on "Continue"

      expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.generic"))
    end
  end

  scenario "When the school selected is ineligible" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    choose_school schools(:bradford_grammar_school)

    expect(page).to have_text("We could not find a school matching those details")
  end

  scenario "when poor performance - subject to formal performance action" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
  end

  scenario "when poor performance - subject to disciplinary action" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
  end

  scenario "when poor performance - subject to disciplinary & formal performance action" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_true"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_true"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
  end

  # Employed as Supply Teacher with contract less than an entire term
  scenario "supply teacher doesn't have a contract for a whole term at same school" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  # Employed as Supply Teacher by Private Agency
  scenario "Supply Teacher employed directly by Private Agency" do
    start_early_career_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    # - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  scenario "when subject for undergraduate ITT or postgraduate ITT is 'none of the above'" do
    start_early_career_payments_claim
    claim = Claim.order(:created_at).last

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

    choose "None of the above"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "none_of_the_above"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.itt_subject"))
  end

  scenario "when no longer teaching an eligible ITT subject" do
    start_early_career_payments_claim
    claim = Claim.order(:created_at).last

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

    choose "Foreign languages"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "foreign_languages"

    # - Do you teach the eligible ITT subject now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject.humanize.downcase))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql false

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.not_teaching_subject"))
  end

  scenario "when academic year completed undergraduate ITT or started postgraduate ITT is 'none of the above'" do
    start_early_career_payments_claim
    claim = Claim.order(:created_at).last

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text(
      I18n.t(
        "early_career_payments.questions.eligible_itt_subject",
        qualification: claim.eligibility.qualification_name
      )
    )
    choose "Foreign languages"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "foreign_languages"

    # - Do you teach the eligible ITT subject now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject.humanize.downcase))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    # - In what academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "None of the above"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql AcademicYear.new

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  [
    {itt_subject: "physics", itt_academic_year: AcademicYear.new(2018)},
    {itt_subject: "physics", itt_academic_year: AcademicYear.new(2019)},
    {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2018)},
    {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2019)},
    {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2018)},
    {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2019)}
  ].each do |scenario|
    scenario "with ITT subject #{scenario[:itt_subject].humanize} in ITT academic year #{scenario[:itt_academic_year]}" do
      start_early_career_payments_claim
      claim = Claim.order(:created_at).last

      # - Which school do you teach at
      expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

      choose_school schools(:penistone_grammar_school)

      # - Are you currently employed as a supply teacher
      expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

      choose "No"
      click_on "Continue"

      # - Poor performance
      expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
      expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

      choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
      choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
      click_on "Continue"

      # - What route into teaching did you take?
      expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

      choose "Undergraduate"
      click_on "Continue"

      expect(claim.eligibility.reload.qualification).to eq "undergraduate_itt"

      # - Which subject did you do your undergraduate ITT in
      expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

      choose scenario[:itt_subject].humanize
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eq scenario[:itt_subject]

      # - Do you teach the eligible ITT subject now
      expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject.humanize.downcase))

      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.teaching_subject_now).to eql true

      # - In what academic year did you start your undergraduate ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

      choose scenario[:itt_academic_year].to_s(:long)
      click_on "Continue"

      expect(claim.eligibility.reload.itt_academic_year).to eql scenario[:itt_academic_year]

      expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
      expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
      expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
    end
  end
end
