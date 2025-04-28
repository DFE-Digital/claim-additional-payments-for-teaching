require "rails_helper"

RSpec.feature "Eligible now can set a reminder for next year." do
  before { FeatureFlag.enable!(:tri_only_journey) }

  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments_only, current_academic_year: AcademicYear.new(2023)) }
  let(:eligibility_attributes) { attributes_for(:targeted_retention_incentive_eligibility, :eligible, current_school_id: school.id) }
  let(:academic_year) { journey_configuration.current_academic_year }
  let(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }

  it "auto-sets a reminders email and name from claim params and displays the correct year" do
    start_targeted_retention_incentive_payments_claim
    reminder_year = (academic_year + 1).start_year

    session = Journeys::TargetedRetentionIncentivePayments::Session.last
    session.answers.assign_attributes(
      attributes_for(
        :targeted_retention_incentive_payments_answers,
        :targeted_retention_incentive_eligible,
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
