# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConfiguration do
  context "with policy configuration records" do
    let!(:student_loans) { create(:policy_configuration, :student_loans) }
    let!(:maths_and_physics) { create(:policy_configuration, :maths_and_physics) }
    let!(:additional_payments) { create(:policy_configuration, :additional_payments) }

    describe ".for" do
      it "returns the configuration for a given policy" do
        expect(described_class.for(StudentLoans)).to eq student_loans
        expect(described_class.for(MathsAndPhysics)).to eq maths_and_physics

        # Same PolicyConfiguration for ECP and LUP
        expect(described_class.for(EarlyCareerPayments)).to eq additional_payments
        expect(described_class.for(LevellingUpPremiumPayments)).to eq additional_payments
      end
    end

    describe ".for_routing_name" do
      it "returns the configuration for a given routing name" do
        expect(described_class.for_routing_name("student-loans")).to eq student_loans
        expect(described_class.for_routing_name("maths-and-physics")).to eq maths_and_physics

        # ECP and LUP use the same routing name and share the same PolicyConfiguration
        expect(described_class.for_routing_name("additional-payments")).to eq additional_payments
      end
    end

    describe "#policies" do
      it "returns the policies" do
        expect(described_class.for(StudentLoans).policies).to eq [StudentLoans]
        expect(described_class.for(MathsAndPhysics).policies).to eq [MathsAndPhysics]
        expect(described_class.for(EarlyCareerPayments).policies).to eq [EarlyCareerPayments, LevellingUpPremiumPayments]
      end
    end

    describe "#routing_name" do
      it "returns routing for PolicyConfiguration" do
        expect(described_class.for(StudentLoans).routing_name).to eq "student-loans"
        expect(described_class.for(MathsAndPhysics).routing_name).to eq "maths-and-physics"

        # Same routing_name for ECP and LUP
        expect(described_class.for(EarlyCareerPayments).routing_name).to eq "additional-payments"
        expect(described_class.for(LevellingUpPremiumPayments).routing_name).to eq "additional-payments"
      end
    end

    describe "#additional_payments?" do
      it "returns true" do
        expect(additional_payments.additional_payments?).to be true
      end

      it "returns false" do
        expect(student_loans.additional_payments?).to be false
        expect(maths_and_physics.additional_payments?).to be false
      end
    end

    describe "validations" do
      it "prevents saving a record for a policy already configured" do
        expect { create(:policy_configuration, policy_types: [EarlyCareerPayments]) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".policy_for_routing_name" do
    it "returns the first policy for that routing name" do
      expect(described_class.policy_for_routing_name("student-loans")).to eq StudentLoans
      expect(described_class.policy_for_routing_name("maths-and-physics")).to eq MathsAndPhysics
      expect(described_class.policy_for_routing_name("additional-payments")).to eq EarlyCareerPayments
    end
  end

  describe ".policies_for_routing_name" do
    it "returns the policies for that routing name" do
      expect(described_class.policies_for_routing_name("student-loans")).to eq [StudentLoans]
      expect(described_class.policies_for_routing_name("maths-and-physics")).to eq [MathsAndPhysics]
      expect(described_class.policies_for_routing_name("additional-payments")).to eq [EarlyCareerPayments, LevellingUpPremiumPayments]
    end
  end

  describe ".view_paths" do
    it "returns any extra view paths" do
      expect(described_class.view_path("additional-payments")).to eq "early_career_payments"
    end

    it "returns nil for no overriding view path for student-loans" do
      expect(described_class.view_path("student-loans")).to be_nil
    end

    it "returns nil for no overriding view path for maths-and-physics" do
      expect(described_class.view_path("maths-and-physics")).to be_nil
    end
  end

  describe ".all_routing_names" do
    it "returns all the routing names" do
      expect(described_class.all_routing_names).to eq ["student-loans", "maths-and-physics", "additional-payments"]
    end
  end

  describe ".routing_name_for_policy" do
    it "returns the routing name" do
      expect(described_class.routing_name_for_policy(StudentLoans)).to eq "student-loans"
      expect(described_class.routing_name_for_policy(MathsAndPhysics)).to eq "maths-and-physics"

      # Same routing_name for ECP and LUP
      expect(described_class.routing_name_for_policy(EarlyCareerPayments)).to eq "additional-payments"
      expect(described_class.routing_name_for_policy(LevellingUpPremiumPayments)).to eq "additional-payments"
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(described_class.new(policy_types: [StudentLoans])).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020-2021")).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020/2021")).to be_valid
  end
end
