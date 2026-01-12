require "rails_helper"

RSpec.describe Admin::Claims::AssignForm do
  let!(:current_admin) { create(:dfe_signin_user, :service_operator) }
  let!(:second_admin) { create(:dfe_signin_user, :service_operator) }
  let!(:third_admin) { create(:dfe_signin_user, :service_operator) }

  let(:claim) do
    create(
      :claim,
      assigned_to: third_admin
    )
  end

  subject do
    described_class.new(current_admin:, claim:)
  end

  describe "#colleagues" do
    it "returns other service operators" do
      expect(subject.colleagues).not_to include current_admin
      expect(subject.colleagues).to include second_admin
    end

    it "excludes currently assigned admin" do
      expect(subject.colleagues).not_to include third_admin
    end
  end
end
