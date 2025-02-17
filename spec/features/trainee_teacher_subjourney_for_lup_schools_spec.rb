require "rails_helper"

RSpec.feature "Trainee teacher subjourney for Targeted Retention Incentive schools" do
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }
  let(:academic_year) { journey_configuration.current_academic_year }

  scenario "non-Targeted Retention Incentive school" do
    non_targeted_retention_incentive_school = create(:school, :early_career_payments_eligible, :targeted_retention_incentive_payments_ineligible)
    expect(Policies::TargetedRetentionIncentivePayments::SchoolEligibility.new(non_targeted_retention_incentive_school)).not_to be_eligible

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    choose_school non_targeted_retention_incentive_school

    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
    expect(page).to have_no_link("Back")
  end

  scenario "Targeted Retention Incentive school with Targeted Retention Incentive ITT subject" do
    get_to_itt_subject_question

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.ineligible.reason.trainee_teacher_future_eligibility"))

    click_on "Set reminder"

    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text("Tell us the email you want us to send reminders to. We recommend you use a non-work email address in case your circumstances change.")

    fill_in "Full name", with: "David Tau"
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
    fill_in "claim-one-time-password-field", with: get_otp_from_email
    click_on "Confirm"
    reminder = Reminder.order(:created_at).last

    expect(reminder.full_name).to eq "David Tau"
    expect(reminder.email_address).to eq "david.tau1988@hotmail.co.uk"
    expect(reminder.itt_academic_year).to eq(academic_year + 1)
    expect(reminder.itt_subject).to eq "mathematics"
    expect(page).to have_text("We have set your reminder")

    mail = ReminderMailer.reminder_set(Reminder.order(:created_at).last)
    expect(mail.template_id).to eq "0dc80ba9-adae-43cd-98bf-58882ee401c3"
  end

  scenario "Targeted Retention Incentive school with non-Targeted Retention Incentive ITT subject but eligible degree" do
    get_to_itt_subject_question

    choose "None of the above"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))

    choose "Yes"
    click_on "Continue"

    I18n.t("additional_payments.ineligible.reason.trainee_teacher_future_eligibility")

    click_on "Set reminder"

    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text("Tell us the email you want us to send reminders to. We recommend you use a non-work email address in case your circumstances change.")

    fill_in "Full name", with: "David Tau"
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
    fill_in "claim-one-time-password-field", with: get_otp_from_email
    click_on "Confirm"
    reminder = Reminder.order(:created_at).last

    expect(reminder.full_name).to eq "David Tau"
    expect(reminder.email_address).to eq "david.tau1988@hotmail.co.uk"
    expect(reminder.itt_academic_year).to eq academic_year + 1
    expect(reminder.itt_subject).to eq "none_of_the_above"
    expect(page).to have_text("We have set your reminder")

    mail = ReminderMailer.reminder_set(Reminder.order(:created_at).last)
    expect(mail.template_id).to eq "0dc80ba9-adae-43cd-98bf-58882ee401c3"
  end

  scenario "Targeted Retention Incentive school with non-Targeted Retention Incentive ITT subject and no eligible degree" do
    get_to_itt_subject_question

    choose "None of the above"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
    expect(page).to have_no_link("Back")
  end

  private

  def get_to_itt_subject_question
    targeted_retention_incentive_school = create(:school, :combined_journey_eligibile_for_all)
    expect(Policies::TargetedRetentionIncentivePayments::SchoolEligibility.new(targeted_retention_incentive_school)).to be_eligible

    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    choose_school targeted_retention_incentive_school

    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.forms.eligible_itt_subject.questions.which_subject_trainee_teacher"))
  end
end
