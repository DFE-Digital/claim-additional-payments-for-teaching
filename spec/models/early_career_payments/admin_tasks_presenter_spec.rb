require "rails_helper"

RSpec.describe EarlyCareerPayments::AdminTasksPresenter, type: :model do
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

  describe "#identity_confirmation" do
    it "returns an array of label and values for displaying information for the identity confirmation check" do
      expect(presenter.identity_confirmation).to eq [
        ["Current school", school.name],
        ["Contact number", school.phone_number]
      ]
    end
  end
end
