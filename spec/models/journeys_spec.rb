# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys do
  describe ".all" do
    it "returns all the journeys" do
      expect(described_class.all).to eq([
        Journeys::TargetedRetentionIncentivePayments,
        Journeys::TeacherStudentLoanReimbursement,
        Journeys::GetATeacherRelocationPayment,
        Journeys::FurtherEducationPayments,
        Journeys::EarlyYearsPayment::Provider::Start,
        Journeys::EarlyYearsPayment::Provider::Authenticated,
        Journeys::EarlyYearsPayment::Provider::AlternativeIdv,
        Journeys::EarlyYearsPayment::Practitioner
      ])
    end
  end

  describe ".all_routing_names" do
    it "returns all the journeys' routing names" do
      expect(described_class.all_routing_names).to eq([
        Journeys::TargetedRetentionIncentivePayments.routing_name,
        Journeys::TeacherStudentLoanReimbursement.routing_name,
        Journeys::GetATeacherRelocationPayment.routing_name,
        Journeys::FurtherEducationPayments.routing_name,
        Journeys::EarlyYearsPayment::Provider::Start.routing_name,
        Journeys::EarlyYearsPayment::Provider::Authenticated.routing_name,
        Journeys::EarlyYearsPayment::Provider::AlternativeIdv.routing_name,
        Journeys::EarlyYearsPayment::Practitioner.routing_name
      ])
    end
  end

  describe ".for_routing_name" do
    subject { described_class.for_routing_name(routing_name) }

    context "with a valid routing name" do
      let(:routing_name) { Journeys::TargetedRetentionIncentivePayments.routing_name }

      it { is_expected.to eq(Journeys::TargetedRetentionIncentivePayments) }
    end

    context "with an invalid routing name" do
      let(:routing_name) { "test" }

      it { is_expected.to be_nil }
    end
  end

  describe ".for_policy" do
    subject { described_class.for_policy(policy) }

    context "with a valid policy" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to eq(Journeys::TargetedRetentionIncentivePayments) }
    end

    context "with an invalid routing name" do
      let(:policy) { "test" }

      it { is_expected.to be_nil }
    end
  end
end
