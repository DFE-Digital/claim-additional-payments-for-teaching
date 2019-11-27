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

    it "returns true when the qts_award_year is before 2014" do
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2014").ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "on_or_after_september_2014").ineligible?).to eql false
    end

    it "returns true when claimant is a supply teacher without a contract of at least one term" do
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: true).ineligible?).to eql false
    end

    it "returns true when claimant is a supply teacher who isn't employed directly by the school" do
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, employed_directly: true).ineligible?).to eql false
    end

    it "returns true when subject to disciplinary action" do
      expect(MathsAndPhysics::Eligibility.new(subject_to_disciplinary_action: true).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(subject_to_disciplinary_action: false).ineligible?).to eql false
    end

    it "returns true when subject to formal performance action" do
      expect(MathsAndPhysics::Eligibility.new(subject_to_formal_performance_action: true).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(subject_to_formal_performance_action: false).ineligible?).to eql false
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
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2014").ineligibility_reason).to eq :ineligible_qts_award_year
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false).ineligibility_reason).to eql :no_entire_term_contract
      expect(MathsAndPhysics::Eligibility.new(subject_to_disciplinary_action: true).ineligibility_reason).to eql :subject_to_disciplinary_action
      expect(MathsAndPhysics::Eligibility.new(subject_to_formal_performance_action: true).ineligibility_reason).to eql :subject_to_formal_performance_action
    end
  end

  describe "#award_amount" do
    it "returns the £2,000 amount that Maths & Physics claimants are eligible for" do
      expect(MathsAndPhysics::Eligibility.new.award_amount).to eq(BigDecimal("2000"))
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
        employed_as_supply_teacher: true,
        has_entire_term_contract: false,
        employed_directly: false,
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

    it "resets has_entire_term_contract when the value of employed_as_supply_teacher changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_entire_term_contract }
        .from(false).to(nil)
    end

    it "resets employed_directly when the value of employed_as_supply_teacher changes" do
      eligibility.employed_as_supply_teacher = true
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.employed_as_supply_teacher = false
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.employed_directly }
        .from(false).to(nil)
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

  context "when saving in the “initial-teacher-training-subject” context" do
    it "validates the presence of initial_teacher_training_subject" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"initial-teacher-training-subject")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :physics)).to be_valid(:"initial-teacher-training-subject")
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
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_september_2014")).to be_valid(:"qts-year")
    end
  end

  context "when saving in the “supply-teacher” context" do
    it "is not valid without a value for employed_as_supply_teacher" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"supply-teacher")
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true)).to be_valid(:"supply-teacher")
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: false)).to be_valid(:"supply-teacher")
    end
  end

  context "when saving in the “entire-term-contract” context, with employed_as_supply_teacher true" do
    it "validates the presence of has_entire_term_contract" do
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"entire-term-contract")
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, has_entire_term_contract: false)).to be_valid(:"entire-term-contract")
    end
  end

  context "when saving in the “employed-directly” context, with employed_as_supply_teacher true" do
    it "validates the presence of employed_directly" do
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true)).not_to be_valid(:"employed-directly")
      expect(MathsAndPhysics::Eligibility.new(employed_as_supply_teacher: true, employed_directly: false)).to be_valid(:"employed-directly")
    end
  end

  context "when saving in the “disciplinary-action” context" do
    it "is not valid without a value for subject_to_disciplinary_action" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"disciplinary-action")
      expect(MathsAndPhysics::Eligibility.new(subject_to_disciplinary_action: true)).to be_valid(:"disciplinary-action")
      expect(MathsAndPhysics::Eligibility.new(subject_to_disciplinary_action: false)).to be_valid(:"disciplinary-action")
    end
  end

  context "when saving in the “formal-performance-action” context" do
    it "is not valid without a value for subject_to_formal_performance_action" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"formal-performance-action")
      expect(MathsAndPhysics::Eligibility.new(subject_to_formal_performance_action: true)).to be_valid(:"formal-performance-action")
      expect(MathsAndPhysics::Eligibility.new(subject_to_formal_performance_action: false)).to be_valid(:"formal-performance-action")
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

    it "is not valid without a value for initial_teacher_training_subject" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for has_uk_maths_or_physics_degree, when initial_teacher_training_specialised_in_maths_or_physics is false" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_specialised_in_maths_or_physics: false, has_uk_maths_or_physics_degree: "no")).to be_valid(:submit)
    end

    it "is not valid without a value for qts_award_year" do
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: "before_september_2014")).to be_valid(:submit)
    end

    it "is not valid without a value for employed_as_supply_teacher" do
      expect(build(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: false)).to be_valid(:submit)
    end

    it "is not valid without a value for has_entire_term_contract and employed_directly, when employed_as_supply_teacher is true" do
      expect(build(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: true, has_entire_term_contract: nil, employed_directly: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: true, has_entire_term_contract: true, employed_directly: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, employed_as_supply_teacher: true, has_entire_term_contract: true, employed_directly: false)).to be_valid(:submit)
    end

    it "is not valid without a value for subject_to_disciplinary_action" do
      expect(build(:maths_and_physics_eligibility, :eligible, subject_to_disciplinary_action: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, subject_to_disciplinary_action: false)).to be_valid(:submit)
    end

    it "is not valid without a value for subject_to_formal_performance_action" do
      expect(build(:maths_and_physics_eligibility, :eligible, subject_to_formal_performance_action: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, subject_to_formal_performance_action: false)).to be_valid(:submit)
    end
  end
end
