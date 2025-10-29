require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::PolicyEligibilityChecker, type: :model do
  let(:policy_eligibility_checker) { described_class.new(answers: answers) }

  describe "#ineligibility_reason" do
    subject { policy_eligibility_checker.ineligibility_reason }

    let!(:journey_configuration) do
      create(
        :journey_configuration,
        :targeted_retention_incentive_payments,
        open_for_submissions: true
      )
    end

    context "when the policy is closed" do
      let(:answers) do
        build(:targeted_retention_incentive_payments_answers)
      end

      before do
        journey_configuration.update!(
          current_academic_year: AcademicYear.new(2086)
        )
      end

      it { is_expected.to eq(:policy_closed) }
    end

    context "when school is tlsr ineligible" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          current_school_id: create(:school).id
        )
      end

      it { is_expected.to eq(:school_ineligible) }
    end

    context "when a supply teacher" do
      context "when lacking entire term contract" do
        let(:answers) do
          build(
            :targeted_retention_incentive_payments_answers,
            employed_as_supply_teacher: true,
            has_entire_term_contract: false
          )
        end

        it { is_expected.to eq(:supply_teacher_contract_ineligible) }
      end

      context "when not employed directly" do
        let(:answers) do
          build(
            :targeted_retention_incentive_payments_answers,
            employed_as_supply_teacher: true,
            has_entire_term_contract: true,
            employed_directly: false
          )
        end

        it { is_expected.to eq(:supply_teacher_contract_ineligible) }
      end
    end

    context "when subject to formal performance action" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          subject_to_formal_performance_action: true
        )
      end

      it { is_expected.to eq(:poor_performance) }
    end

    context "when subject to disciplinary action" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          subject_to_disciplinary_action: true
        )
      end

      it { is_expected.to eq(:poor_performance) }
    end

    # For TSLR you can't really get this ineligibility reason as
    # both subject symbols and ineligible_cohort check the itt year is in the
    # past 5 years. We're stubbing subject symbols here so we can test this
    # as it's in the `common_ineligible_attributes?` method. We'll be removing
    # `common_ineligible_attributes` once we switch to the TSLR only journey
    # so can remove this then.
    context "when ineligible cohort" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          itt_academic_year: AcademicYear.new(2000)
        )
      end

      before do
        allow(Policies::TargetedRetentionIncentivePayments).to(
          receive(:fixed_subject_symbols).and_return([:mathematics])
        )
      end

      it { is_expected.to eq(:ineligible_cohort) }
    end

    context "when insufficient teaching" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          teaching_subject_now: false
        )
      end

      it { is_expected.to eq(:insufficient_teaching) }
    end

    context "when ineligible subject and no eligible degree subject" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          eligible_itt_subject: :none_of_the_above,
          eligible_degree_subject: false
        )
      end

      it { is_expected.to eq(:subject_and_degree_ineligible) }
    end

    context "when trainee teacher in the last policy year" do
      let(:answers) do
        build(
          :targeted_retention_incentive_payments_answers,
          :trainee_teacher
        )
      end

      before do
        policy_end_year = Policies::TargetedRetentionIncentivePayments::POLICY_END_YEAR
        journey_configuration.update!(current_academic_year: policy_end_year)
      end

      it { is_expected.to eq(:trainee_in_last_policy_year) }
    end
  end

  describe "#ineligible?" do
    subject { policy_eligibility_checker.ineligible? }

    context "when current academic year is 2022/23" do
      before {
        create(
          :journey_configuration,
          :targeted_retention_incentive_payments,
          current_academic_year: AcademicYear.new(2022)
        )
      }

      context "when ITT year is 2017" do
        let(:answers) {
          build(
            :targeted_retention_incentive_payments_answers,
            itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2017))
          )
        }

        it { is_expected.to be false }
      end

      context "without eligible degree" do
        let(:answers) {
          build(
            :targeted_retention_incentive_payments_answers,
            :targeted_retention_incentive_eligible,
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
end
