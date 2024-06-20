require "rails_helper"

describe Policies::InternationalRelocationPayments::PolicyEligibilityChecker do
  let(:answers) do
    build(
      :get_a_teacher_relocation_payment_answers,
      application_route: application_route
    )
  end

  let(:checker) { described_class.new(answers: answers) }

  describe "#status" do
    subject { checker.status }

    context "when the application route is 'other'" do
      let(:application_route) { "other" }

      it { is_expected.to eq(:ineligible) }
    end

    context "when the application route is 'teacher'" do
      let(:application_route) { "teacher" }

      it { is_expected.to eq(:eligible_now) }
    end

    context "when the application route is 'salaried_trainee'" do
      let(:application_route) { "salaried_trainee" }

      it { is_expected.to eq(:eligible_now) }
    end
  end

  describe "#ineligible?" do
    subject { checker.ineligible? }

    context "when the application route is 'other'" do
      let(:application_route) { "other" }

      it { is_expected.to eq(true) }
    end

    context "when the application route is 'teacher'" do
      let(:application_route) { "teacher" }

      it { is_expected.to eq(false) }
    end

    context "when the application route is 'salaried_trainee'" do
      let(:application_route) { "salaried_trainee" }

      it { is_expected.to eq(false) }
    end
  end
end
