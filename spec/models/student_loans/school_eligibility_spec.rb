require "rails_helper"

RSpec.describe StudentLoans::SchoolEligibility do
  describe "#eligible_claim_school?" do
    context "with a secondary school" do
      let(:secondary_school) {
        School.new(
          school_type_group: :la_maintained,
          phase: :secondary,
          close_date: nil,
          local_authority: local_authorities(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary school in an eligible local authority" do
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_claim_school?).to eql true
      end

      it "returns false when closed before the policy start date" do
        secondary_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE - 1.month)
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_claim_school?).to eql false
      end

      it "returns true when closed after the policy start date" do
        secondary_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE + 1.month)
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_claim_school?).to eql true
      end

      it "returns false when not in an eligible local authority" do
        secondary_school.assign_attributes(local_authority: local_authorities(:camden))
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_claim_school?).to eql false
      end

      it "returns false when not state funded" do
        secondary_school.assign_attributes(school_type_group: :independent_schools)
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_claim_school?).to eql false
      end
    end

    context "with a special school" do
      let(:special_school) {
        School.new(
          close_date: nil,
          school_type: :community_special_school,
          school_type_group: :special_schools,
          statutory_high_age: 16,
          local_authority: local_authorities(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary equivalent special school in an eligible local authority district" do
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql true
      end

      it "returns false when closed before the policy start date" do
        special_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE - 1.month)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql false
      end
      it "returns true when closed after the policy start date" do
        special_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE + 1.month)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql true
      end

      it "returns false when not in an eligble local authority" do
        special_school.assign_attributes(local_authority: local_authorities(:camden))
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql false
      end

      it "returns false when not state funded" do
        special_school.assign_attributes(school_type_group: :independent_schools)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        special_school.assign_attributes(statutory_high_age: 11)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_claim_school?).to eql false
      end
    end

    context "with alternative provision school" do
      let(:alternative_provision_school) {
        School.new(
          close_date: nil,
          school_type_group: :la_maintained,
          school_type: :pupil_referral_unit,
          statutory_high_age: 19, local_authority: local_authorities(:barnsley)
        )
      }

      it "returns true with an open, state funded secondary equivalent alternative provision school in an eligible local authority" do
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eq true
      end

      it "returns false when closed before the policy start date" do
        alternative_provision_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE - 1.month)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eql false
      end

      it "returns true when closed after the policy start date" do
        alternative_provision_school.assign_attributes(close_date: StudentLoans::SchoolEligibility::POLICY_START_DATE + 1.month)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eql true
      end

      it "returns false when not in an eligble local authority" do
        alternative_provision_school.assign_attributes(local_authority: local_authorities(:camden))
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        alternative_provision_school.assign_attributes(statutory_high_age: 11)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eq false
      end

      it "returns true with a secure unit" do
        alternative_provision_school.assign_attributes(school_type_group: :other, school_type: :secure_unit)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_claim_school?).to eq true
      end
    end

    context "when it is not a secondary school" do
      it "returns false" do
        primary_school = School.new(phase: :primary, school_type_group: :la_maintained, local_authority: local_authorities(:barnsley))
        expect(StudentLoans::SchoolEligibility.new(primary_school).eligible_claim_school?).to eql false
      end
    end
  end

  describe "#eligible_current_school?" do
    context "with a secondary school" do
      let(:secondary_school) {
        School.new(
          school_type_group: :la_maintained,
          phase: :secondary,
          close_date: nil
        )
      }

      it "returns true with an open, state funded secondary school" do
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        secondary_school.assign_attributes(close_date: Date.new)
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql false
      end

      it "returns false when not state funded" do
        secondary_school.assign_attributes(school_type_group: :independent_schools)
        expect(StudentLoans::SchoolEligibility.new(secondary_school).eligible_current_school?).to eql false
      end
    end

    context "with a special school" do
      let(:special_school) {
        School.new(
          close_date: nil,
          school_type: :community_special_school,
          school_type_group: :special_schools,
          statutory_high_age: 16
        )
      }

      it "returns true with an open, state funded secondary equivalent special school" do
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_current_school?).to eql true
      end

      it "returns false when closed" do
        special_school.assign_attributes(close_date: Date.new)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end

      it "returns false when not state funded" do
        special_school.assign_attributes(school_type_group: :independent_schools)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        special_school.assign_attributes(statutory_high_age: 11)
        expect(StudentLoans::SchoolEligibility.new(special_school).eligible_current_school?).to eql false
      end
    end

    context "with alternative provision school" do
      let(:alternative_provision_school) {
        School.new(
          close_date: nil,
          school_type_group: :la_maintained,
          school_type: :pupil_referral_unit,
          statutory_high_age: 19
        )
      }

      it "returns true with an open, state funded secondary equivalent alternative provision school" do
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end

      it "returns false when closed" do
        alternative_provision_school.assign_attributes(close_date: Date.new)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eql false
      end

      it "returns false when not secondary equivalent" do
        alternative_provision_school.assign_attributes(statutory_high_age: 11)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq false
      end

      it "returns true with a secure unit" do
        alternative_provision_school.assign_attributes(school_type_group: :other, school_type: :secure_unit)
        expect(StudentLoans::SchoolEligibility.new(alternative_provision_school).eligible_current_school?).to eq true
      end
    end

    context "when it is not a secondary school" do
      it "returns false" do
        primary_school = School.new(phase: :primary, school_type_group: :la_maintained)
        expect(StudentLoans::SchoolEligibility.new(primary_school).eligible_current_school?).to eql false
      end
    end
  end
end
