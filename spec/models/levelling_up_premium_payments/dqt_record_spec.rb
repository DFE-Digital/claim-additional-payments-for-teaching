require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::DqtRecord do
  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build(
      :claim,
      policy: LevellingUpPremiumPayments,
      academic_year: AcademicYear.new(2022),
      eligibility: eligibility
    )
  end

  let(:eligibility) do
    build(
      :levelling_up_premium_payments_eligibility,
      :eligible,
      eligible_itt_subject: eligible_itt_subject,
      qualification: qualification,
      itt_academic_year: itt_academic_year
    )
  end

  let(:eligible_itt_subject) { :mathematics }
  let(:qualification) { :postgraduate_itt }
  let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: degree_codes,
        itt_subjects: ["mathematics"],
        itt_subject_codes: itt_subject_codes,
        itt_start_date: Date.parse("1/9/2019"),
        qts_award_date: Date.parse("31/8/2019"),
        qualification_name: "Postgraduate Certificate in Education"
      }
    )
  end

  let(:itt_subject_codes) { [] }
  let(:degree_codes) { [] }

  describe "#eligible?" do
    context "without ITT and degree codes" do
      it { is_expected.not_to be_eligible }
    end

    context "with invalid ITT and degree codes" do
      let(:itt_subject_codes) { ["123"] }
      let(:degree_codes) { ["321"] }

      it { is_expected.not_to be_eligible }
    end

    context "with valid ITT code" do
      let(:itt_subject_codes) { ["G100"] }

      it { is_expected.to be_eligible }
    end

    context "with valid degree code" do
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }
    end

    context "with invalid ITT and valid degree codes" do
      let(:itt_subject_codes) { ["123"] }
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }
    end

    context "with valid ITT and degree codes" do
      let(:itt_subject_codes) { ["G100"] }
      let(:degree_codes) { ["I100"] }

      it { is_expected.to be_eligible }

      context "when the selected subject doesn't match" do
        let(:eligible_itt_subject) { :physics }

        it { is_expected.not_to be_eligible }
      end

      context "when the selected qualification doesn't match" do
        let(:qualification) { :undergraduate_itt }

        it { is_expected.not_to be_eligible }
      end

      context "when the selected year doesn't match" do
        let(:itt_academic_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

        it { is_expected.not_to be_eligible }
      end
    end
  end
end
