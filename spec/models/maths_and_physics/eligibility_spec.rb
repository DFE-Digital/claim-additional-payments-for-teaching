require "rails_helper"

RSpec.describe MathsAndPhysics::Eligibility, type: :model do
  let(:eligible_school) { build(:school, :maths_and_physics_eligible) }
  let(:ineligible_school) { build(:school, :maths_and_physics_ineligible) }

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(MathsAndPhysics::Eligibility.new.ineligible?).to eql false
    end

    it "returns true when not teaching maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: false).ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(teaching_maths_or_physics: true).ineligible?).to eql false
    end

    describe "eligibility of schools" do
      subject(:eligibility) { MathsAndPhysics::Eligibility.new(current_school: school) }

      context "with an ineligible school" do
        let(:school) { ineligible_school }

        it { is_expected.to be_ineligible }
      end

      context "with an eligible school" do
        let(:school) { eligible_school }

        it { is_expected.not_to be_ineligible }
      end
    end

    it "returns true when initial teacher training was not in science and the claimant has no degree in maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "no").ineligible?).to eql true
    end

    it "returns false if they have a degree in maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "yes").ineligible?).to eql false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "has_non_uk").ineligible?).to eql false

      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science, initial_teacher_training_subject_specialism: :chemistry, has_uk_maths_or_physics_degree: "yes").ineligible?).to eql false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science, initial_teacher_training_subject_specialism: :chemistry, has_uk_maths_or_physics_degree: "has_non_uk").ineligible?).to eql false
    end

    it "returns false if they are not sure about their ITT specialism, even if they don't have a degree" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science, initial_teacher_training_subject_specialism: :not_sure, has_uk_maths_or_physics_degree: "no").ineligible?).to eql false
    end

    it "returns true when the qts_award_year is before the qualifiying cut-off" do
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_cut_off_date").ineligible?).to eql true
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "on_or_after_cut_off_date").ineligible?).to eql false
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
      expect(MathsAndPhysics::Eligibility.new(current_school: ineligible_school).ineligibility_reason).to eq :ineligible_current_school
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "no").ineligibility_reason).to eq :no_maths_or_physics_qualification
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_cut_off_date").ineligibility_reason).to eq :ineligible_qts_award_year
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
      eligibility = MathsAndPhysics::Eligibility.new(current_school: eligible_school)
      expect(eligibility.current_school_name).to eq eligibility.current_school.name
    end

    it "does not error if the current school is not set" do
      expect(MathsAndPhysics::Eligibility.new.current_school_name).to be_nil
    end
  end

  describe "#initial_teacher_training_specialised_in_maths_or_physics?" do
    it "returns true when the ITT subject is maths or physics" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :maths).initial_teacher_training_specialised_in_maths_or_physics?).to be true
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :physics).initial_teacher_training_specialised_in_maths_or_physics?).to be true

      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science).initial_teacher_training_specialised_in_maths_or_physics?).to be false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects).initial_teacher_training_specialised_in_maths_or_physics?).to be false
    end

    it "returns true when the ITT specialism is physics" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject_specialism: :physics).initial_teacher_training_specialised_in_maths_or_physics?).to be true

      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject_specialism: :biology).initial_teacher_training_specialised_in_maths_or_physics?).to be false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject_specialism: :chemistry).initial_teacher_training_specialised_in_maths_or_physics?).to be false
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject_specialism: :not_sure).initial_teacher_training_specialised_in_maths_or_physics?).to be false
    end
  end

  describe "#reset_dependent_answers" do
    let(:eligibility) do
      create(
        :maths_and_physics_eligibility,
        :eligible,
        initial_teacher_training_subject: :science,
        initial_teacher_training_subject_specialism: :chemistry,
        has_uk_maths_or_physics_degree: "no",
        employed_as_supply_teacher: true,
        has_entire_term_contract: false,
        employed_directly: false
      )
    end

    it "resets initial_teacher_training_subject_specialism and has_uk_maths_or_physics_degree when the value of initial_teacher_training_subject changes" do
      eligibility.initial_teacher_training_subject = :science
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.initial_teacher_training_subject = :maths
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_uk_maths_or_physics_degree }
        .from("no").to(nil)
        .and change { eligibility.initial_teacher_training_subject_specialism }
        .from("chemistry").to(nil)
    end

    it "resets has_uk_maths_or_physics_degree when initial_teacher_training_subject changes without the specialism changing" do
      eligibility.update_columns(initial_teacher_training_subject: "none_of_the_subjects", initial_teacher_training_subject_specialism: nil)

      eligibility.initial_teacher_training_subject = :none_of_the_subjects
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.initial_teacher_training_subject = :maths
      expect { eligibility.reset_dependent_answers }
        .to change { eligibility.has_uk_maths_or_physics_degree }
        .from("no").to(nil)
    end

    it "resets has_uk_maths_or_physics_degree when the value of initial_teacher_training_subject_specialism changes" do
      eligibility.initial_teacher_training_subject_specialism = :chemistry
      expect { eligibility.reset_dependent_answers }.not_to change { eligibility.attributes }

      eligibility.initial_teacher_training_subject_specialism = :physics
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

  describe "#qts_award_year_answer" do
    it "returns a String representing the answer of the QTS question based on qts_award_year and the academic year the claim was made in" do
      claim = Claim.new(academic_year: 2019)
      eligibility = MathsAndPhysics::Eligibility.new(claim: claim)

      eligibility.qts_award_year = :before_cut_off_date
      expect(eligibility.qts_award_year_answer).to eq "In or before the academic year 2013 to 2014"

      eligibility.qts_award_year = :on_or_after_cut_off_date
      expect(eligibility.qts_award_year_answer).to eq "In or after the academic year 2014 to 2015"

      claim.academic_year = "2020/2021"
      expect(eligibility.qts_award_year_answer).to eq "In or after the academic year 2015 to 2016"
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
      expect(MathsAndPhysics::Eligibility.new(current_school: eligible_school)).to be_valid(:"current-school")
    end
  end

  context "when saving in the “initial-teacher-training-subject” context" do
    it "validates the presence of initial_teacher_training_subject" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"initial-teacher-training-subject")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :physics)).to be_valid(:"initial-teacher-training-subject")
    end
  end

  context "when saving in the “initial-teacher-training-subject-specialism” context with an initial_teacher_training_subject of science" do
    it "validates the presence of initial_teacher_training_subject_specialism" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science)).not_to be_valid(:"initial-teacher-training-subject-specialism")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :science, initial_teacher_training_subject_specialism: :chemistry)).to be_valid(:"initial-teacher-training-subject-specialism")
    end
  end

  context "when saving in the “has-uk-maths-or-physics-degree” context and initial_teacher_training_specialised_in_maths_or_physics is false" do
    it "validates the presence of has_uk_maths_or_physics_degree" do
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects)).not_to be_valid(:"has-uk-maths-or-physics-degree")
      expect(MathsAndPhysics::Eligibility.new(initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "no")).to be_valid(:"has-uk-maths-or-physics-degree")
    end
  end

  context "when saving in the “qts-year” context" do
    it "validates the presence of qts_award_year" do
      expect(MathsAndPhysics::Eligibility.new).not_to be_valid(:"qts-year")
      expect(MathsAndPhysics::Eligibility.new(qts_award_year: "before_cut_off_date")).to be_valid(:"qts-year")
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
      expect(build(:maths_and_physics_eligibility, :eligible, current_school: eligible_school)).to be_valid(:submit)
    end

    it "is not valid without a value for initial_teacher_training_subject" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for has_uk_maths_or_physics_degree, when initial_teacher_training_specialised_in_maths_or_physics is false" do
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: :none_of_the_subjects, has_uk_maths_or_physics_degree: "no")).to be_valid(:submit)
    end

    it "is not valid without a value for initial_teacher_training_subject_specialism when the initial_teacher_training_subject is science" do
      eligibility = build(:maths_and_physics_eligibility, :eligible, initial_teacher_training_subject: :science, initial_teacher_training_subject_specialism: nil, has_uk_maths_or_physics_degree: "yes")
      expect(eligibility).not_to be_valid(:submit)

      eligibility.initial_teacher_training_subject_specialism = :physics
      expect(eligibility).to be_valid(:submit)
    end

    it "is not valid without a value for qts_award_year" do
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: nil)).not_to be_valid(:submit)
      expect(build(:maths_and_physics_eligibility, :eligible, qts_award_year: "before_cut_off_date")).to be_valid(:submit)
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

  describe "#eligible_itt_subject" do
    it "returns nil" do
      expect(StudentLoans::Eligibility.new.eligible_itt_subject).to be(nil)
    end
  end
end
