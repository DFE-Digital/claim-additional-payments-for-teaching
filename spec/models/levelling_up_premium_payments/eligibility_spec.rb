require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Eligibility, type: :model do
  subject { build(:levelling_up_premium_payments_eligibility) }

  describe "associations" do
    it { should have_one(:claim) }
    it { should belong_to(:current_school).class_name("School").optional(true) }
  end

  describe "#policy" do
    specify { expect(subject.policy).to eq(LevellingUpPremiumPayments) }
  end

  describe "#ineligible?" do
    context "when current academic year is 2022/23" do
      before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2022)) }
      specify { expect(subject).to respond_to(:ineligible?) }

      context "when ITT year is 2017" do
        before do
          subject.itt_academic_year = AcademicYear::Type.new.serialize(AcademicYear.new(2017))
        end

        it "returns false" do
          expect(subject.ineligible?).to eql false
        end
      end

      describe "ITT subject" do
        let(:eligible) { build(:levelling_up_premium_payments_eligibility, :eligible) }

        context "without eligible degree" do
          before { eligible.eligible_degree_subject = false }

          it "is eligible then switches to ineligible with a non-LUP ITT subject" do
            expect(eligible).not_to be_ineligible
            eligible.itt_subject_foreign_languages!
            expect(eligible).to be_ineligible
          end
        end
      end
    end
  end

  describe "#eligible_now?" do
    before { create(:journey_configuration, :additional_payments) }

    context "eligible now" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible_now) }

      it { is_expected.to be_eligible_now }
    end

    context "eligible later" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible_later) }

      it { is_expected.not_to be_eligible_now }
    end
  end

  describe "#eligible_later?" do
    before { create(:journey_configuration, :additional_payments) }

    context "eligible now" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible_now) }

      it { is_expected.not_to be_eligible_later }
    end

    context "eligible later" do
      subject { build(:levelling_up_premium_payments_eligibility, :eligible_later) }

      it { is_expected.to be_eligible_later }
    end
  end

  describe "#award_amount" do
    before do
      create(:journey_configuration, :additional_payments)
      create(:levelling_up_premium_payments_award, award_amount: 3_000)
    end

    it { should_not allow_values(0, nil).for(:award_amount).on(:amendment) }
    it { should validate_numericality_of(:award_amount).on(:amendment).is_greater_than(0).is_less_than_or_equal_to(3_000).with_message("Enter a positive amount up to £3,000.00 (inclusive)") }
  end

  it_behaves_like "Eligibility status", :levelling_up_premium_payments

  context "LUP-specific eligibility" do
    before { create(:journey_configuration, :additional_payments) }

    subject { eligibility.status }

    context "ECP-only ITT subject" do
      let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :ineligible_itt_subject) }

      it { is_expected.to eq(:ineligible) }
    end

    context "ITT subject or degree subject" do
      context "good ITT subject and no degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :lup_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:eligible_now) }
      end

      context "bad ITT subject but have a degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :ineligible_itt_subject, :relevant_degree) }

        it { is_expected.to eq(:eligible_now) }
      end

      context "bad ITT subject and no degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :ineligible_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:ineligible) }
      end
    end

    context "trainee teacher" do
      context "good ITT subject and no degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :trainee_teacher, :lup_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:eligible_later) }
      end

      context "bad ITT subject but have a degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :trainee_teacher, :ineligible_itt_subject, :relevant_degree) }

        it { is_expected.to eq(:eligible_later) }
      end

      context "bad ITT subject and no degree" do
        let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible_now, :trainee_teacher, :ineligible_itt_subject, :no_relevant_degree) }

        it { is_expected.to eq(:ineligible) }
      end
    end
  end

  describe "#set_qualifications_from_dqt_record" do
    let(:eligibility) { build(:levelling_up_premium_payments_eligibility, claim:, itt_academic_year:, eligible_itt_subject:, qualification:, eligible_degree_subject:) }
    let(:claim) { build(:claim, policy: LevellingUpPremiumPayments, qualifications_details_check:) }
    let(:itt_academic_year) { AcademicYear.new(2021) }
    let(:eligible_itt_subject) { :mathematics }
    let(:qualification) { :postgraduate_itt }
    let(:eligible_degree_subject) { false }

    context "when user has confirmed their qualification details" do
      let(:qualifications_details_check) { true }
      let(:dbl) { double(itt_academic_year_for_claim:, eligible_itt_subject_for_claim:, route_into_teaching:, eligible_degree_code?: eligible_degree_code) }
      let(:itt_academic_year_for_claim) { AcademicYear.new(2022) }
      let(:eligible_itt_subject_for_claim) { :computing }
      let(:route_into_teaching) { :undergraduate_itt }
      let(:eligible_degree_code) { true }

      before { allow(claim).to receive(:dqt_teacher_record).and_return(dbl) }

      it "sets the qualification answers to those returned by LevellingUpPremiumPayments::DqtRecord" do
        expect { eligibility.set_qualifications_from_dqt_record }.to change { eligibility.itt_academic_year }.from(itt_academic_year).to(itt_academic_year_for_claim)
          .and change { eligibility.eligible_itt_subject }.from(eligible_itt_subject.to_s).to(eligible_itt_subject_for_claim.to_s)
          .and change { eligibility.qualification }.from(qualification.to_s).to(route_into_teaching.to_s)
          .and change { eligibility.eligible_degree_subject }.from(eligible_degree_subject).to(eligible_degree_code)
      end

      context "when the DQT record is missing data" do
        let(:itt_academic_year_for_claim) { nil }
        let(:eligible_itt_subject_for_claim) { nil }
        let(:route_into_teaching) { nil }
        let(:eligible_degree_code) { nil }

        it "does not change the answers" do
          expect(eligibility.set_qualifications_from_dqt_record).to eq(eligibility.attributes.symbolize_keys.slice(:itt_academic_year, :eligible_itt_subject, :qualification, :eligible_degree_subject).transform_values { |v| (v == false) ? v : v.to_s })
        end
      end
    end

    context "when user has not confirmed their qualification details" do
      let(:qualifications_details_check) { false }

      it "sets the qualification answers to nil" do
        expect { eligibility.set_qualifications_from_dqt_record }.to change { eligibility.itt_academic_year }.from(itt_academic_year).to(nil)
          .and change { eligibility.eligible_itt_subject }.from(eligible_itt_subject.to_s).to(nil)
          .and change { eligibility.qualification }.from(qualification.to_s).to(nil)
          .and change { eligibility.eligible_degree_subject }.from(eligible_degree_subject).to(nil)
      end
    end
  end
end
