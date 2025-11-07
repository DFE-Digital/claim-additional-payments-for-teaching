require "rails_helper"

RSpec.feature "unsubscribe from reminders" do
  let(:reminder) do
    create(
      :reminder,
      journey_class: Journeys::FurtherEducationPayments.to_s
    )
  end

  scenario "happy path" do
    visit "/#{reminder.journey.routing_name}/unsubscribe/reminders/#{reminder.id}"
    expect(page).to have_content "Are you sure you wish to unsub"

    click_button("Unsubscribe")

    expect(reminder.reload.deleted_at).to be_present

    expect(page).to have_content "Unsubscribe complete"
  end

  scenario "when reminder does not exist" do
    visit "/#{reminder.journey.routing_name}/unsubscribe/reminders/idonotexist"
    expect(page).to have_content "We can’t find your subscription"
  end

  context "when reminder already soft deleted" do
    let(:reminder) do
      create(
        :reminder,
        :soft_deleted,
        journey_class: Journeys::FurtherEducationPayments.to_s
      )
    end

    scenario "cannot find subscription" do
      visit "/#{reminder.journey.routing_name}/unsubscribe/reminders/#{reminder.id}"
      expect(page).to have_content "We can’t find your subscription"
    end
  end
end
