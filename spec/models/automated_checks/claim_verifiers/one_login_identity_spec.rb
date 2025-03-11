require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::OneLoginIdentity do
  describe "#perform" do
    subject do
      described_class.new(claim:, admin_user: nil)
    end

    context "when identity_confirmed_with_onelogin? is false" do
      let(:claim) do
        create(
          :claim,
          identity_confirmed_with_onelogin: false
        )
      end

      it "does not create a task" do
        expect {
          subject.perform
        }.not_to change(Task, :count)
      end
    end

    context "when identity_confirmed_with_onelogin is true" do
      context "when there data matches" do
        let(:claim) do
          create(:claim, :submitted, :with_onelogin_idv_data)
        end

        it "creates a passed task" do
          expect {
            subject.perform
          }.to change(Task.passed_automatically, :count).by(1)
        end
      end

      context "when there is a data mis-match" do
        let(:claim) do
          create(
            :claim,
            :submitted,
            :with_onelogin_idv_data,
            first_name: "John",
            surname: "Doe",
            onelogin_idv_first_name: "Tom",
            onelogin_idv_last_name: "Jones",
            onelogin_idv_full_name: "Tom Jones"
          )
        end

        it "creates a failed task" do
          expect {
            subject.perform
          }.to change(Task.where(passed: false), :count).by(1)
        end
      end

      context "when there is a DOB mis-match" do
        let(:claim) do
          create(
            :claim,
            :submitted,
            :with_onelogin_idv_data,
            date_of_birth: Date.new(1980, 12, 13),
            onelogin_idv_date_of_birth: Date.new(1970, 1, 1)
          )
        end

        it "creates a failed task" do
          expect {
            subject.perform
          }.to change(Task.where(passed: false), :count).by(1)
        end
      end
    end
  end
end
