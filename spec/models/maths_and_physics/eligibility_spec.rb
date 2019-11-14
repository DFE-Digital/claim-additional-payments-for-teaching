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
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(MathsAndPhysics::Eligibility.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: false).ineligibility_reason).to eq :not_teaching_maths_or_physics
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
  end
end
