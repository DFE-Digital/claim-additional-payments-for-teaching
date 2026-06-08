require "rails_helper"

RSpec.feature "EYTFI feedback", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )
  end

  scenario "claimant submits feedback" do
    visit eytfi_guidance_path(
      journey: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )
    click_link "feedback"

    expect(page).to have_text "Give feedback on Claim an early years teacher recognition payment"
    choose "Very satisfied"
    choose "A specific area"
    choose "Uploading proof of employment"
    fill_in "How could we improve this service? (optional)", with: "some comment"
    choose "Yes"
    fill_in "What is your email address?", with: "claimant@example.com"
    fill_in "Occupation", with: "Teacher"
    expect {
      click_button "Submit feedback"
    }.to change(Feedback, :count).by(1)

    expect(page).to have_text "Feedback submitted"

    feedback = Feedback.last

    expect(feedback.rating).to eql "very_satisfied"
    expect(feedback.area).to eql "specific_page"
    expect(feedback.specific_page).to eql "uploading"
    expect(feedback.comment).to eql "some comment"
    expect(feedback.research_participation).to be_truthy
    expect(feedback.email_address).to eql "claimant@example.com"
    expect(feedback.occupation).to eql "Teacher"

    expect(feedback.origin).to eql "http://www.example.com/early-years-teachers-recognition-payments/guidance"
    expect(feedback.claim_id).to be_nil
  end
end
