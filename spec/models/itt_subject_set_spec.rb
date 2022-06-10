# frozen_string_literal: true

require "rails_helper"

RSpec.describe IttSubjectSet, type: :component do
  describe "#subjects" do
    context "trainee teacher" do
      subject { described_class.new(trainee_teacher: true).subjects }

      it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
    end

    context "2017/18" do
      let(:year) { AcademicYear.new(2017) }

      context "eligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false).subjects }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true).subjects }

        it { is_expected.to be_empty }
      end
    end

    context "2018/19" do
      let(:year) { AcademicYear.new(2018) }

      context "eligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false).subjects }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true).subjects }

        it { is_expected.to contain_exactly(:mathematics) }
      end
    end

    context "2019/20" do
      let(:year) { AcademicYear.new(2019) }

      context "eligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false).subjects }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true).subjects }

        it { is_expected.to contain_exactly(:mathematics) }
      end
    end

    context "2020/21" do
      let(:year) { AcademicYear.new(2020) }

      context "eligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false).subjects }

        it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true).subjects }

        it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
      end
    end

    context "2021/22" do
      let(:year) { AcademicYear.new(2021) }

      context "eligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false).subjects }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { described_class.new(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true).subjects }

        it { is_expected.to be_empty }
      end
    end
  end

  describe ".from_current_claim" do
    let(:ecp_claim_2021) { build(:claim, academic_year: "2021/2022", policy: EarlyCareerPayments) }
    let(:eligible_lup_claim_2021) { build(:claim, academic_year: "2021/2022", eligibility: build(:levelling_up_premium_payments_eligibility, :eligible)) }
    let(:current_claim) { CurrentClaim.new(claims: [ecp_claim_2021, eligible_lup_claim_2021]) }

    subject { described_class.from_current_claim(current_claim).subjects }

    it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
  end
end
