require "rails_helper"

RSpec.feature "Trainee Teacher - Early Career Payments - journey" do
  context "when Claim AcademicYear is not 2021" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "cannot enter the journey to request a reminder" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

      choose "No"
      click_on "Continue"

      claim = Claim.order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.nqt_in_academic_year_after_itt).to eql false
      expect(page).to have_text("You are not eligible")
    end
  end

  # As a one off due to the COVID Pandemic halting Teacher Training in 2020 and 2021
  # a new journey was introduced so that if the Claim Academic Year for the policy is
  # 20201, then claimants will have an extra year to complete their ITT
  # As such, they have answered "No I am a Trainee Teacher" to the NQT question (Q1)
  # and can setup a reminder so they can make a claim in 2022
  context "when Claim AcademicYear is 2021" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2021))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "successfully completes the journey" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

      choose "No, I’m a trainee teacher"
      click_on "Continue"

      claim = Claim.order(:created_at).last
      eligibility = claim.eligibility

      expect(eligibility.nqt_in_academic_year_after_itt).to eql false
      expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

      # - Which subject did you do your postgraduate ITT in
      expect(page).to have_text(
        I18n.t(
          "early_career_payments.questions.eligible_itt_subject",
          qualification: claim.eligibility.qualification_name
        )
      )
      choose "Mathematics"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

      # - In what academic year did you start your postgraduate ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

      choose "2018 to 2019"
      click_on "Continue"

      expect(claim.eligibility.reload.itt_academic_year).to eql AcademicYear.new(2018)

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

      expect(page).to have_text("We will send you a reminder in September 2022")
    end
  end
end
