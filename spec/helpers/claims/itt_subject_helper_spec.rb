require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  describe "#subjects" do
    context "trainee teacher" do
      subject { helper.subjects(trainee_teacher: true) }

      it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
    end

    context "2017/18" do
      let(:year) { AcademicYear.new(2017) }

      context "eligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false) }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true) }

        it { is_expected.to be_empty }
      end
    end

    context "2018/19" do
      let(:year) { AcademicYear.new(2018) }

      context "eligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false) }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true) }

        it { is_expected.to contain_exactly(:mathematics) }
      end
    end

    context "2019/20" do
      let(:year) { AcademicYear.new(2019) }

      context "eligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false) }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true) }

        it { is_expected.to contain_exactly(:mathematics) }
      end
    end

    context "2020/21" do
      let(:year) { AcademicYear.new(2020) }

      context "eligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false) }

        it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true) }

        it { is_expected.to contain_exactly(:chemistry, :foreign_languages, :mathematics, :physics) }
      end
    end

    context "2021/22" do
      let(:year) { AcademicYear.new(2021) }

      context "eligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: false) }

        it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
      end

      context "ineligible for LUP" do
        subject { helper.subjects(trainee_teacher: false, itt_academic_year: year, ineligible_for_lup: true) }

        it { is_expected.to be_empty }
      end
    end
  end
end
