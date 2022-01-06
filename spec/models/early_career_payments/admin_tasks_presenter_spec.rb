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
        ["Qualification", "Undergraduate initial teacher training (ITT)"],
        ["ITT end year", "In the academic year 2018 to 2019"],
        ["ITT subject", "Mathematics"]
      ]

      expect(presenter.qualifications).to eq expected_array
    end

    it "sets the “Award year” value based on the academic year the claim was made in" do
      expected_qts_answer = presenter.qualifications[1][1]
      expect(expected_qts_answer).to eq "In the academic year 2018 to 2019"
    end

    [
      {qualification: :assessment_only, qualification_text: "Assessment only", year_text: "end", subject_text: :physics},
      {qualification: :overseas_recognition, qualification_text: "Overseas recognition", year_text: "end", subject_text: :chemistry},
      {qualification: :postgraduate_itt, qualification_text: "Postgraduate initial teacher training (ITT)", year_text: "start", subject_text: :foreign_languages},
      {qualification: :undergraduate_itt, qualification_text: "Undergraduate initial teacher training (ITT)", year_text: "end", subject_text: :mathematics}
    ].each do |spec|
      context "with qualification #{spec[:qualification]}" do
        let(:claim) do
          build(
            :claim,
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2023)),
            eligibility: build(
              :early_career_payments_eligibility,
              current_school: school,
              eligible_itt_subject: spec[:subject_text],
              itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
              qualification: qualification
            )
          )
        end

        let(:qualification) { spec[:qualification] }

        it "returns array with qualification #{spec[:qualification_text]}" do
          expect(presenter.qualifications).to include(
            ["Qualification", spec[:qualification_text]]
          )
        end

        it "returns array with year #{spec[:year_text]}" do
          expect(presenter.qualifications).to include(
            ["ITT #{spec[:year_text]} year", "In the academic year 2020 to 2021"]
          )
        end

        it "returns array with subject #{spec[:subject_text]}" do
          expect(presenter.qualifications).to include(
            ["ITT subject", I18n.t("early_career_payments.answers.eligible_itt_subject.#{spec[:subject_text]}")]
          )
        end
      end
    end
  end
end
