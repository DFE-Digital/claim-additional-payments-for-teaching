require "rails_helper"

RSpec.feature "Eligible now can set a reminder for next year." do
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }
  let(:eligibility_attributes) { attributes_for(:early_career_payments_eligibility, :eligible, current_school_id: school.id) }
  let(:academic_year) { journey_configuration.current_academic_year }
  let(:school) { create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_eligible) }

  it "auto-sets a reminders email and name from claim params and displays the correct year" do
    start_early_career_payments_claim
    reminder_year = (academic_year + 1).start_year

    session = Journeys::AdditionalPaymentsForTeaching::Session.last
    session.answers.assign_attributes(
      attributes_for(
        :additional_payments_answers,
        :ecp_and_lup_eligible,
        :submittable,
        current_school_id: school.id
      )
    )
    session.save!

    jump_to_claim_journey_page(
      slug: "check-your-answers",
      journey_session: session
    )
    expect(page).to have_text(session.answers.first_name)
    click_on "Accept and send"
    expect(page).to have_text("Set a reminder to apply next year")
    click_on "Set reminder"
    expect(page).to have_text("We will send you a reminder by email in September #{reminder_year}")
  end
end

RSpec.feature "Completed Applications - Reminders" do
  [
    {
      policy_year: AcademicYear.new(2022),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), invited_to_set_reminder: true},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true}
      ]
    },
    {
      policy_year: AcademicYear.new(2023),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018), invited_to_set_reminder: false},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true}
      ]
    },
    {
      policy_year: AcademicYear.new(2024),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false}
      ]
    }
  ].each do |policy|
    context "when accepting claims for AcademicYear #{policy[:policy_year]}" do
      let!(:journey_configuration) { create(:journey_configuration, :additional_payments, current_academic_year: policy[:policy_year]) }
      let(:academic_year) { journey_configuration.current_academic_year }
      let(:school) { create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_eligible) }

      policy[:eligible_now].each do |scenario|
        reminder_status = (scenario[:invited_to_set_reminder] == true) ? "CAN" : "CANNOT"
        scenario "with cohort ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} - a reminder #{reminder_status} be set" do
          start_early_career_payments_claim
          reminder_year = (academic_year + 1).start_year

          session = Journeys::AdditionalPaymentsForTeaching::Session.last
          session.answers.assign_attributes(
            attributes_for(
              :additional_payments_answers,
              :submittable,
              :ecp_and_lup_eligible,
              itt_academic_year: scenario[:itt_academic_year],
              eligible_itt_subject: scenario[:itt_subject],
              current_school_id: school.id
            )
          )
          session.save!

          jump_to_claim_journey_page(
            slug: "check-your-answers",
            journey_session: session
          )
          expect(page).to have_text(session.answers.first_name)

          click_on "Accept and send"

          expect(page).to have_text("You applied for an early-career payment")
          expect(page).to have_text("Your reference number")
          expect(Claim.count).to eq 1
          submitted_claim = Claim.last
          expect(page).to have_text(submitted_claim.reference.to_s)

          if scenario[:invited_to_set_reminder] == true
            expect(page).to have_text("Set a reminder to apply next year")
            click_on "Set reminder"
            expect(page).to have_text("We will send you a reminder by email in September #{reminder_year}")
          elsif scenario[:invited_to_set_reminder] == false
            expect(page).not_to have_text("Set a reminder to apply next year")
            expect(page).not_to have_link("Set reminder")
          end
          expect(page).to have_text("What do you think of this service?")
        end
      end
    end
  end
end
