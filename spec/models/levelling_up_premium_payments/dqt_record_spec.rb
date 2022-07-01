require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::DqtRecord do
  subject(:dqt_record) do
    described_class.new(
      record,
      claim
    )
  end

  let(:claim) do
    build_stubbed(
      :claim,
      academic_year: AcademicYear.new(2022)
    )
  end

  let(:record) do
    OpenStruct.new(
      {
        degree_codes: degree_codes,
        itt_subjects: ["Applied Mathematics"],
        itt_subject_codes: itt_subject_codes,
        itt_start_date: Date.parse("1/9/2018"),
        qts_award_date: Date.parse("31/8/2019"),
        qualification_name: "BA"
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
    end
  end
end
