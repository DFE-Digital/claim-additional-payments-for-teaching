require "rails_helper"

RSpec.describe Policies::LevellingUpPremiumPayments::PolicyEligibilityChecker, type: :model do
  let(:policy_eligibility_checker) { described_class.new(answers: answers) }

  describe "#ineligible?" do
    subject { policy_eligibility_checker.ineligible? }

    context "when current academic year is 2022/23" do
      before {
        create(
          :journey_configuration,
          :additional_payments,
          current_academic_year: AcademicYear.new(2022)
        )
      }

      context "when ITT year is 2017" do
        let(:answers) {
          build(
            :additional_payments_answers,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2017))
          )
        }

        it { is_expected.to be false }
      end

      context "without eligible degree" do
        let(:answers) {
          build(
            :additional_payments_answers,
            :lup_eligible,
            eligible_degree_subject: false,
            eligible_itt_subject: itt_subject
          )
        }

        context "with eligible subject" do
          let(:itt_subject) { :mathematics }

          it { is_expected.to be false }
        end

        context "with ineligible subject" do
          let(:itt_subject) { :foreign_languages }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe "#eligible_now?" do
    before { create(:journey_configuration, :additional_payments) }

    subject { policy_eligibility_checker.eligible_now? }

    context "eligible now" do
      let(:answers) {
        build(
          :additional_payments_answers,
          :lup_eligible
        )
      }

      it { is_expected.to be true }
    end

    context "eligible later" do
      let(:answers) {
        build(
          :additional_payments_answers,
          :lup_eligible_later
        )
      }

      it { is_expected.to be false }
    end
  end

  describe "#eligible_later?" do
    before do
      create(
        :journey_configuration,
        :additional_payments,
        current_academic_year: AcademicYear.new(2023)
      )
    end

    subject { policy_eligibility_checker.eligible_later? }

    context "eligible now" do
      let(:answers) {
        build(
          :additional_payments_answers,
          :lup_eligible
        )
      }

      it { is_expected.to be false }
    end

    context "eligible later" do
      let(:answers) {
        build(
          :additional_payments_answers,
          :lup_eligible_later
        )
      }

      it { is_expected.to be true }
    end
  end

  describe "#status" do
    before do
      create(
        :journey_configuration,
        :additional_payments,
        current_academic_year: AcademicYear.new(2023)
      )
    end

    subject { policy_eligibility_checker.status }

    it_behaves_like "eligibility_status", :levelling_up_premium_payments

    context "ECP-only ITT subject" do
      let(:answers) { build(:additional_payments_answers, :lup_eligible, :lup_ineligible_itt_subject) }

      it { is_expected.to eq(:ineligible) }
    end

    context "ITT subject or degree subject" do
      context "good ITT subject and no degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :no_relevant_degree) }

        it { is_expected.to eq(:eligible_now) }
      end

      context "bad ITT subject but have a degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :lup_ineligible_itt_subject, :relevant_degree) }

        it { is_expected.to eq(:eligible_now) }
      end

      context "bad ITT subject and no degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :lup_ineligible_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:ineligible) }
      end
    end

    context "trainee teacher" do
      context "good ITT subject and no degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :trainee_teacher, :no_relevant_degree) }

        it { is_expected.to eq(:eligible_later) }
      end

      context "bad ITT subject but have a degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :trainee_teacher, :lup_ineligible_itt_subject, :relevant_degree) }

        it { is_expected.to eq(:eligible_later) }
      end

      context "bad ITT subject and no degree" do
        let(:answers) { build(:additional_payments_answers, :lup_eligible, :trainee_teacher, :lup_ineligible_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:ineligible) }
      end
    end
  end
end
