require "rails_helper"

RSpec.describe "unsubscribe", type: :request do
  let!(:reminder) { create(:reminder, :with_fe_reminder) }

  describe "POST #create" do
    context "happy path" do
      it "unsubscribes from reminder via one click unsubscribe" do
        expect {
          post "/further-education-payments/unsubscribe/reminders", params: {id: reminder.id}
        }.to change(Reminder, :count).by(-1)

        expect(response).to be_successful
      end
    end

    context "when no such reminder" do
      it "returns 400 error" do
        post "/further-education-payments/unsubscribe/reminders", params: {id: "idonotexist"}

        expect(response).to be_bad_request
      end
    end
  end
end
