require "rails_helper"

RSpec.describe Admin::MyClaims do
  let(:current_admin) do
    create(
      :dfe_signin_user,
      :service_operator
    )
  end

  let(:second_admin) do
    create(
      :dfe_signin_user,
      :service_operator
    )
  end

  subject do
    described_class.new(current_admin:)
  end

  describe "#overdue" do
    let!(:my_overdue_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        submitted_at: 1.year.ago
      )
    end

    let!(:my_not_overdue_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin
      )
    end

    let!(:other_admin_overdue_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: second_admin,
        submitted_at: 1.year.ago
      )
    end

    it "returns my overdue claims" do
      expect(subject.overdue).to include(my_overdue_claim)
      expect(subject.overdue).not_to include(my_not_overdue_claim)
      expect(subject.overdue).not_to include(other_admin_overdue_claim)
    end
  end

  describe "#due_today" do
    around :each do |example|
      travel_to Time.zone.local(2026, 1, 14, 12) do
        example.run
      end
    end

    let!(:my_due_today_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        submitted_at: Date.new(2025, 9, 3)
      )
    end

    let!(:my_due_another_day_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin
      )
    end

    it "returns my due today claims" do
      expect(subject.due_today).to include(my_due_today_claim)
      expect(subject.due_today).not_to include(my_due_another_day_claim)
    end
  end

  describe "#due_in_7_days" do
    around :each do |example|
      travel_to Time.zone.local(2026, 1, 14, 12) do
        example.run
      end
    end

    let!(:my_due_early_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        submitted_at: Date.new(2025, 9, 3)
      )
    end

    let!(:my_due_late_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        submitted_at: Date.new(2025, 9, 10)
      )
    end

    let!(:my_due_another_day_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin
      )
    end

    it "returns my due claims" do
      expect(subject.due_in_7_days).to include(my_due_early_claim)
      expect(subject.due_in_7_days).to include(my_due_late_claim)
      expect(subject.due_in_7_days).not_to include(my_due_another_day_claim)
    end
  end

  describe "#on_hold" do
    let!(:my_on_hold_claim) do
      create(
        :claim,
        :submitted,
        :held,
        assigned_to: current_admin
      )
    end

    let!(:my_not_on_hold_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin
      )
    end

    it "returns my due claims" do
      expect(subject.on_hold).to include(my_on_hold_claim)
      expect(subject.on_hold).not_to include(my_not_on_hold_claim)
    end
  end

  describe "#active_claims" do
    let!(:my_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin
      )
    end

    let(:eligibility) do
      create(
        :early_years_payments_eligibility,
        start_date: nil
      )
    end

    let!(:my_claim_with_no_deadline) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        policy: Policies::EarlyYearsPayments,
        eligibility:
      )
    end

    let!(:my_claim_with_no_submitted_at) do
      create(
        :claim,
        :submitted,
        assigned_to: current_admin,
        policy: Policies::EarlyYearsPayments,
        submitted_at: nil
      )
    end

    let!(:not_my_claim) do
      create(
        :claim,
        :submitted,
        assigned_to: second_admin
      )
    end

    let!(:my_approved_claim) do
      create(
        :claim,
        :submitted,
        :approved,
        assigned_to: current_admin
      )
    end

    let!(:my_rejected_claim) do
      create(
        :claim,
        :submitted,
        :rejected,
        assigned_to: current_admin
      )
    end

    it "returns all my active claims" do
      expect(subject.active_claims).to include(my_claim)
      expect(subject.active_claims).to include(my_claim_with_no_submitted_at)
      expect(subject.active_claims).to include(my_claim_with_no_deadline)
      expect(subject.active_claims).not_to include(not_my_claim)
      expect(subject.active_claims).not_to include(my_approved_claim)
      expect(subject.active_claims).not_to include(my_rejected_claim)
    end

    it "orders claims correctly" do
      expect(subject.active_claims).to eql([my_claim_with_no_submitted_at, my_claim, my_claim_with_no_deadline])
    end
  end
end
