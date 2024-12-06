require "rails_helper"

RSpec.describe "unsubscribe", type: :request do
  let(:reminder) { create(:reminder, :with_fe_reminder) }

  describe "POST #create" do
    context "happy path" do
      it "sets deleted_at from reminder via one click unsubscribe" do
        post "/further-education-payments/unsubscribe/reminders", params: {id: reminder.id}

        expect(reminder.reload.deleted_at).to be_present

        expect(response).to be_successful
      end
    end

    context "when no such reminder" do
      it "returns 400 error" do
        post "/further-education-payments/unsubscribe/reminders", params: {id: "idonotexist"}

        expect(response).to be_bad_request
      end
    end

    context "when already soft deleted" do
      let(:reminder) { create(:reminder, :with_fe_reminder, :soft_deleted) }

      it "returns 400 error" do
        post "/further-education-payments/unsubscribe/reminders", params: {id: reminder.id}

        expect(response).to be_bad_request
      end
    end
  end
end
