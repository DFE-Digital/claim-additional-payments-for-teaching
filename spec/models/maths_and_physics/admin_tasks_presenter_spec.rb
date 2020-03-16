require "rails_helper"

RSpec.describe MathsAndPhysics::AdminTasksPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(:claim,
      academic_year: "2019/2020",
      eligibility: build(:maths_and_physics_eligibility,
        teaching_maths_or_physics: true,
        current_school: school,
        initial_teacher_training_subject: :maths,
        initial_teacher_training_subject_specialism: nil,
        qts_award_year: "on_or_after_cut_off_date"))
  end
  subject(:presenter) { described_class.new(claim) }

  describe "#qualifications" do
    it "returns an array of label and values for displaying information for qualification checks" do
      expected_array = [
        ["Award year", "In or after the academic year 2014 to 2015"],
        ["ITT subject", "Maths"]
      ]
      expect(presenter.qualifications).to eq expected_array
    end

    it "sets the “Award year” value based on the academic year the claim was made in" do
      claim.academic_year = "2021/2022"

      expected_qts_answer = presenter.qualifications[0][1]
      expect(expected_qts_answer).to eq "In or after the academic year 2016 to 2017"
    end

    it "includes the subject specialism if they chose science" do
      eligibility.initial_teacher_training_subject = :science
      eligibility.initial_teacher_training_subject_specialism = :physics

      expected_array = [
        ["Award year", "In or after the academic year 2014 to 2015"],
        ["ITT subject", "Physics"]
      ]
      expect(presenter.qualifications).to eq expected_array
    end

    it "includes the their degree if they didn't choose maths or physics for their ITT subject" do
      eligibility.initial_teacher_training_subject = :science
      eligibility.initial_teacher_training_subject_specialism = :biology
      eligibility.has_uk_maths_or_physics_degree = :yes

      expected_array = [
        [I18n.t("admin.qts_award_year"), "In or after the academic year 2014 to 2015"],
        ["ITT subject", "Biology"],
        ["Maths or Physics degree", "UK Maths or Physics degree"]
      ]
      expect(presenter.qualifications).to eq expected_array
    end
  end

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
end
