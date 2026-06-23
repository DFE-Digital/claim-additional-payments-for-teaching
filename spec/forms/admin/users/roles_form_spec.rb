require "rails_helper"

RSpec.describe Admin::Users::RolesForm, type: :model do
  describe "validations" do
    it do
      permitted = [
        "product",
        "support",
        "privileged_support",
        "payroll",
        "admin",
      ]

      is_expected
        .to(
          validate_inclusion_of(:roles).in_array(permitted).with_message("Select a valid role")
        )
    end
  end

  describe "#save" do
    let(:user) { create(:dfe_signin_user) }

    subject do
      described_class.new(user:, roles: ["payroll"])
    end

    it "updates roles" do
      expect {
        subject.save
      }.to change { user.reload.roles }.from([]).to(["payroll"])
    end

    context "when validation error" do
      subject do
        described_class.new(user:, roles: ["foo"])
      end

      it "does not update roles" do
        expect {
          subject.save
        }.not_to change { user.reload.roles }
      end
    end
  end
end
