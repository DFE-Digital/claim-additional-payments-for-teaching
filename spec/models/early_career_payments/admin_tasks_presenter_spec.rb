require "rails_helper"

RSpec.describe EarlyCareerPayments::AdminTasksPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility) { claim.eligibility }

  let(:claim) do
    build(
      :claim,
      academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
      eligibility: build(
        :early_career_payments_eligibility,
        current_school: school,
        eligible_itt_subject: :mathematics,
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
      )
    )
  end

  subject(:presenter) { described_class.new(claim) }

  describe "#identity_confirmation" do
    it "returns an array of label and values for displaying information for the identity confirmation check" do
      expect(presenter.identity_confirmation).to eq [
        ["Current school", school.name],
        ["Contact number", school.phone_number]
      ]
    end
  end

  describe "#qualifications" do
    it "returns an array of label and values for displaying information for qualification checks" do
      expected_array = [
        ["ITT start/end year", "In the academic year 2018 to 2019"],
        ["ITT subject", "Mathematics"]
      ]

      expect(presenter.qualifications).to eq expected_array
    end

    it "sets the “Award year” value based on the academic year the claim was made in" do
      expected_qts_answer = presenter.qualifications[0][1]
      expect(expected_qts_answer).to eq "In the academic year 2018 to 2019"
    end
  end
end
