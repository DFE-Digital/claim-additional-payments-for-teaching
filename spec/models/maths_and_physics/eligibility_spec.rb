require "rails_helper"

RSpec.describe MathsAndPhysics::Eligibility, type: :model do
  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(MathsAndPhysics::Eligibility.new.ineligible?).to eql false
    end

    it "returns true when not teaching maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: false).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: true).ineligible?).to eql false
    end

    it "returns true when teaching at an ineligble school" do
      expect(MathsAndPhysics::Eligibility.new(current_school: schools(:hampstead_school)).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(current_school: schools(:penistone_grammar_school)).ineligible?).to eql false
    end

    it "returns true when initial teacher training did not specialise in maths or physics and claimant has no degree in maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "no").ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "yes").ineligible?).to eql false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "has_non_uk").ineligible?).to eql false
    end

    it "returns true when the qts_award_year is before 2013" do
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2013").ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "on_or_after_september_2013").ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(MathsAndPhysics::Eligibility.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: false).ineligibility_reason).to eq :not_teaching_maths_or_physics
      expect(MathsAndPhysics::Eligibility.new(current_school: schools(:hampstead_school)).ineligibility_reason).to eq :ineligible_current_school
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "no").ineligibility_reason).to eq :no_maths_or_physics_qualification
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2013").ineligibility_reason).to eq :ineligible_qts_award_year
    end
  end

  describe "#current_school_name" do
    it "returns the name of the current school" do
      eligibility = MathsAndPhysics::Eligibility.new(current_school: schools(:penistone_grammar_school))
      expect(eligibility.current_school_name).to eq schools(:penistone_grammar_school).name
    end

    it "does not error if the current school is not set" do
      expect(MathsAndPhysics::Eligibility.new.current_school_name).to be_nil
    end
  end

  describe "#reset_dependent_answers" do
    let(:eligibility) do
      create(
        :maths_and_physics_eligibility,
        :eligible,
        initial_teacher_training_specialised_in_maths_or_physics: false,
        has_uk_maths_or_physics_degree: "no",
      )
    end

    it "resets has_uk_maths_or_physics_degree when the value of initial_teacher_training_specialised_in_maths_or_physics changes" do
      eligibility.initial_teacher_training_specialised_in_maths_or_physics = false
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.initial_teacher_training_specialised_in_maths_or_physics = true
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_uk_maths_or_physics_degree }
        .from("no").to(nil)
    end
  end

  # Validation contexts
  context "when saving in the “teaching-maths-or-physics” context" do
    it "is not valid without a value for teaching_maths_or_physics" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"teaching-maths-or-physics")
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: true)).to be_valid(:"teaching-maths-or-physics")
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: false)).to be_valid(:"teaching-maths-or-physics")
    end
  end

  context "when saving in the “current-school” context" do
    it "validates the presence of the current_school" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"current-school")
      expect(MathsAndPhysics::Eligibility.new(current_school: schools(:penistone_grammar_school))).to be_valid(:"current-school")
    end
  end

  context "when saving in the “initial-teacher-training-specialised-in-maths-or-physics” context" do
    it "validates the presence of initial_teacher_training_specialised_in_maths_or_physics" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"initial-teacher-training-specialised-in-maths-or-physics")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: true)).to be_valid(:"initial-teacher-training-specialised-in-maths-or-physics")
    end
  end

  context "when saving in the “has-uk-maths-or-physics-degree” context, with initial_teacher_training_specialised_in_maths_or_physics false" do
    it "validates the presence of has_uk_maths_or_physics_degree" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false)).not_to be_valid(:"has-uk-maths-or-physics-degree")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "no")).to be_valid(:"has-uk-maths-or-physics-degree")
    end
  end

  context "when saving in the “qts-year” context" do
    it "validates the presence of qts_award_year" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"qts-year")
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2013")).to be_valid(:"qts-year")
    end
  end

  context "when saving in the “submit” context" do
    it "is valid when all attributes are present" do
      expect(build(:maths_and_physics_eligibility, :eligible)).to be_valid(:submit)
    end

    it "is not valid without a value for teaching_maths_or_physics" do
      expect(build(:maths_and_physics_eligibility, :eligible, teaching_maths_or_physics: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, teaching_maths_or_physics: true)).to be_valid(:submit)
    end

    it "is not valid without a value for current_school" do
      expect(build(:maths_and_physics_eligibility, :eligible, current_school: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, current_school: schools(:penistone_grammar_school))).to be_valid(:submit)
    end

    it "is not valid without a value for initial_teacher_training_specialised_in_maths_or_physics" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: true)).to be_valid(:submit)
    end

    it "is not valid without a value for has_uk_maths_or_physics_degree, when initial_teacher_training_specialised_in_maths_or_physics is false" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "no")).to be_valid(:submit)
    end

    it "is not valid without a value for qts_award_year" do
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: "before_september_2013")).to be_valid(:submit)
    end
  end
end
