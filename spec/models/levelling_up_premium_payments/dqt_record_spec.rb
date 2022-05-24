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
        degree_codes: [],
        itt_subjects: ["Applied Mathematics"],
        itt_subject_codes: ["G1100"],
        itt_start_date: Date.parse("1/9/2018"),
        qts_award_date: Date.parse("31/8/2019"),
        qualification_name: "BA"
      }
    )
  end

  describe "#eligible?" do
    subject(:eligible?) { dqt_record.eligible? }

    it "returns true" do
      expect(subject).to be true
    end
  end
end
