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
        itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
        qualification: qualification
      )
    )
  end

  let(:qualification) { :undergraduate_itt }

  subject(:presenter) { described_class.new(claim) }

  describe "#employment" do
    it "returns an array of label and values for displaying information for employment checks" do
      expect(presenter.employment).to eq [
        [I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)]
      ]
    end
  end

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
        ["Qualification", "Undergraduate ITT"],
        ["ITT start/end year", "In the academic year 2018 to 2019"],
        ["ITT subject", "Mathematics"]
      ]

      expect(presenter.qualifications).to eq expected_array
    end

    it "sets the “Award year” value based on the academic year the claim was made in" do
      expected_qts_answer = presenter.qualifications[1][1]
      expect(expected_qts_answer).to eq "In the academic year 2018 to 2019"
    end

    [
      {qualification: :assessment_only, text: "Assessment only"},
      {qualification: :overseas_recognition, text: "Overseas recognition"},
      {qualification: :postgraduate_itt, text: "Postgraduate ITT"},
      {qualification: :undergraduate_itt, text: "Undergraduate ITT"}
    ].each do |spec|
      context "with qualification #{spec[:qualification]}" do
        let(:qualification) { spec[:qualification] }

        it "returns array with qualification #{spec[:text]}" do
          expect(presenter.qualifications).to include(
            ["Qualification", spec[:text]]
          )
        end
      end
    end
  end
end
