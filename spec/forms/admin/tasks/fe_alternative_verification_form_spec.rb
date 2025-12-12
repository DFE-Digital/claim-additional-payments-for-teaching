require "rails_helper"

RSpec.describe Admin::Tasks::EyAlternativeVerificationForm, type: :model do
  let(:claim) do
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments
    )
  end

  let(:admin) { create(:dfe_signin_user) }

  let(:form) do
    described_class.new(claim: claim, admin_user: admin)
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:personal_details_match)
        .with_message("You must select ‘Yes’ or ‘No’")
      )
    end

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:bank_details_match)
        .with_message("You must select ‘Yes’ or ‘No’")
      )
    end
  end

  describe "#initialise" do
    context "when the task exists" do
      it "sets the attributes from the task data" do
        task = create(
          :task,
          :failed,
          name: "ey_alternative_verification",
          claim: claim,
          data: {
            "personal_details_match" => false,
            "bank_details_match" => true
          }
        )

        form = described_class.new(claim: claim, admin_user: admin)

        expect(form.task).to eq task
        expect(form.personal_details_match).to be false
        expect(form.bank_details_match).to be true
      end
    end
  end

  describe "#save" do
    context "when both fields are true" do
      it "passes the task" do
        form.personal_details_match = true
        form.bank_details_match = true

        expect(form.save).to be true

        expect(form.task.passed).to be true
        expect(form.task.manual).to be true
        expect(form.task.created_by).to eq admin
        expect(form.task.data).to eq(
          "personal_details_match" => true,
          "bank_details_match" => true
        )
      end
    end

    context "when personal details match is false" do
      it "fails the task" do
        form.personal_details_match = false
        form.bank_details_match = true

        expect(form.save).to be true

        expect(form.task.passed).to be false
        expect(form.task.manual).to be true
        expect(form.task.created_by).to eq admin
        expect(form.task.data).to eq(
          "personal_details_match" => false,
          "bank_details_match" => true
        )
      end
    end

    context "when bank details match is false" do
      it "fails the task" do
        form.personal_details_match = true
        form.bank_details_match = false

        expect(form.save).to be true

        expect(form.task.passed).to be false
        expect(form.task.manual).to be true
        expect(form.task.created_by).to eq admin
        expect(form.task.data).to eq(
          "personal_details_match" => true,
          "bank_details_match" => false
        )
      end
    end
  end
end
