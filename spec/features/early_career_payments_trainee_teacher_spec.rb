require "rails_helper"

RSpec.feature "Trainee Teacher - Early Career Payments - journey" do
  context "when Claim AcademicYear is 2022/2023" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "successfully completes the journey for computing 2018/19" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start now"

      # - Which school do you teach at
      expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

      choose_school schools(:penistone_grammar_school)

      # - NQT in Academic Year after ITT
      expect(page).to have_text("your first year as an early career teacher?")

      choose "No, I’m a trainee teacher"
      click_on "Continue"

      claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.nqt_in_academic_year_after_itt).to eql false

      # TODO: not sure why this needs setting?
      expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

      # - Which subject did you do your postgraduate ITT in
      expect(page).to have_text(
        I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher")
      )

      expect(page).to have_no_text("Foreign languages")

      choose "Computing"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "computing"

      expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.trainee_teacher_only_in_claim_academic_year_2021"))
      expect(page).to have_text("If you’re a trainee teacher and plan to complete your studies in this academic year you might be able to apply in the next academic year.")
      expect(page).to have_text("Set up a reminder with us")
      expect(page).to have_link(href: new_reminder_path(EarlyCareerPayments.routing_name))

      click_on "Continue"

      fill_in "Full name", with: "Miss Jessica Rabbit"
      fill_in "Email address", with: "mjr@example.com"
      click_on "Continue"

      reminder = Reminder.order(:created_at).last
      expect(reminder.reload.full_name).to eq "Miss Jessica Rabbit"
      expect(reminder.email_address).to eq "mjr@example.com"

      fill_in "reminder_one_time_password", with: get_otp_from_email
      click_on "Confirm"

      expect(page).to have_text("We will send you a reminder in September")
    end

    scenario "successfully completes the journey for chemistry 2020/21" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start now"

      # - Which school do you teach at
      expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

      choose_school schools(:penistone_grammar_school)

      # - NQT in Academic Year after ITT
      expect(page).to have_text("your first year as an early career teacher?")

      choose "No, I’m a trainee teacher"
      click_on "Continue"

      claim = Claim.by_policy(EarlyCareerPayments).order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.nqt_in_academic_year_after_itt).to eql false
      expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

      # - Which subject did you do your postgraduate ITT in
      expect(page).to have_text(
        I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher")
      )
      choose "Chemistry"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "chemistry"

      expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.trainee_teacher_only_in_claim_academic_year_2021"))
      expect(page).to have_text("If you’re a trainee teacher and plan to complete your studies in this academic year you might be able to apply in the next academic year.")
      expect(page).to have_text("Set up a reminder with us")
      expect(page).to have_link(href: new_reminder_path(EarlyCareerPayments.routing_name))

      click_on "Continue"

      fill_in "Full name", with: "Miss Jessica Rabbit"
      fill_in "Email address", with: "mjr@example.com"
      click_on "Continue"

      reminder = Reminder.order(:created_at).last
      expect(reminder.reload.full_name).to eq "Miss Jessica Rabbit"
      expect(reminder.email_address).to eq "mjr@example.com"

      fill_in "reminder_one_time_password", with: get_otp_from_email
      click_on "Confirm"

      expect(page).to have_text("We will send you a reminder in September")
    end
  end
end
