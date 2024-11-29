require "rails_helper"

RSpec.feature "unsubscribe from reminders" do
  let(:reminder) do
    create(
      :reminder,
      journey_class: Journeys::FurtherEducationPayments.to_s
    )
  end

  scenario "happy path" do
    visit "/#{reminder.journey::ROUTING_NAME}/unsubscribe/reminders/#{reminder.id}"
    expect(page).to have_content "Are you sure you wish to unsub"

    expect {
      click_button("Unsubscribe")
    }.to change(Reminder, :count).by(-1)

    expect(page).to have_content "Unsubscribe complete"
  end

  scenario "when reminder does not exist" do
    visit "/#{reminder.journey::ROUTING_NAME}/unsubscribe/reminders/idonotexist"
    expect(page).to have_content "We can’t find your subscription"
  end
end
