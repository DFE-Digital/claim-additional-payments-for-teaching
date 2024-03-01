# frozen_string_literal: true

require "rails_helper"

RSpec.describe JourneyConfiguration do
  context "with journey configuration records" do
    let!(:student_loans) { create(:journey_configuration, :student_loans) }
    let!(:additional_payments) { create(:journey_configuration, :additional_payments) }

    describe ".for" do
      it "returns the configuration for a given policy" do
        expect(described_class.for(StudentLoans)).to eq student_loans

        # Same JourneyConfiguration for ECP and LUP
        expect(described_class.for(Policies::EarlyCareerPayments)).to eq additional_payments
        expect(described_class.for(LevellingUpPremiumPayments)).to eq additional_payments
      end
    end

    describe ".for_routing_name" do
      it "returns the configuration for a given routing name" do
        expect(described_class.for_routing_name("student-loans")).to eq student_loans

        # ECP and LUP use the same routing name and share the same JourneyConfiguration
        expect(described_class.for_routing_name("additional-payments")).to eq additional_payments
      end
    end

    describe "#policies" do
      it "returns the policies" do
        expect(described_class.for(StudentLoans).policies).to eq [StudentLoans]
        expect(described_class.for(Policies::EarlyCareerPayments).policies).to eq [Policies::EarlyCareerPayments, LevellingUpPremiumPayments]
      end
    end

    describe "#routing_name" do
      it "returns routing for JourneyConfiguration" do
        expect(described_class.for(StudentLoans).routing_name).to eq "student-loans"

        # Same routing_name for ECP and LUP
        expect(described_class.for(Policies::EarlyCareerPayments).routing_name).to eq "additional-payments"
        expect(described_class.for(LevellingUpPremiumPayments).routing_name).to eq "additional-payments"
      end
    end

    describe "#additional_payments?" do
      it "returns true" do
        expect(additional_payments.additional_payments?).to be true
      end

      it "returns false" do
        expect(student_loans.additional_payments?).to be false
      end
    end

    describe "validations" do
      it "prevents saving a record for a policy already configured" do
        expect { create(:journey_configuration, policy_types: [Policies::EarlyCareerPayments]) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".policy_for_routing_name" do
    it "returns the first policy for that routing name" do
      expect(described_class.policy_for_routing_name("student-loans")).to eq StudentLoans
      expect(described_class.policy_for_routing_name("additional-payments")).to eq Policies::EarlyCareerPayments
    end
  end

  describe ".policies_for_routing_name" do
    it "returns the policies for that routing name" do
      expect(described_class.policies_for_routing_name("student-loans")).to eq [StudentLoans]
      expect(described_class.policies_for_routing_name("additional-payments")).to eq [Policies::EarlyCareerPayments, LevellingUpPremiumPayments]
    end
  end

  describe ".view_paths" do
    it "returns any extra view paths" do
      expect(described_class.view_path("additional-payments")).to eq "additional_payments"
    end

    it "returns nil for no overriding view path for student-loans" do
      expect(described_class.view_path("student-loans")).to eq "student_loans"
    end
  end

  describe ".all_routing_names" do
    it "returns all the routing names" do
      expect(described_class.all_routing_names).to eq ["student-loans", "additional-payments"]
    end
  end

  describe ".routing_name_for_policy" do
    it "returns the routing name" do
      expect(described_class.routing_name_for_policy(StudentLoans)).to eq "student-loans"

      # Same routing_name for ECP and LUP
      expect(described_class.routing_name_for_policy(Policies::EarlyCareerPayments)).to eq "additional-payments"
      expect(described_class.routing_name_for_policy(LevellingUpPremiumPayments)).to eq "additional-payments"
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(described_class.new(policy_types: [StudentLoans])).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020-2021")).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020/2021")).to be_valid
  end
end
