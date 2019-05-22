require "rails_helper"

RSpec.describe TslrClaim, type: :model do
  it { should belong_to(:claim_school).optional }
  it { should belong_to(:current_school).optional }

  context "when saving in the “qts-year” validation context" do
    let(:custom_validation_context) { :"qts-year" }

    it "validates the qts_award_year is one of the allowable values" do
      expect(TslrClaim.new).not_to be_valid(custom_validation_context)
      expect(TslrClaim.new(qts_award_year: "123")).not_to be_valid(custom_validation_context)

      TslrClaim::VALID_QTS_YEARS.each do |academic_year|
        expect(TslrClaim.new(qts_award_year: academic_year)).to be_valid(custom_validation_context)
      end
    end
  end

  context "when saving in the “claim-school” validation context" do
    let(:custom_validation_context) { :"claim-school" }

    it "it validates the claim_school" do
      expect(TslrClaim.new).not_to be_valid(custom_validation_context)
      expect(TslrClaim.new(claim_school: schools(:penistone_grammar_school))).to be_valid(custom_validation_context)
    end
  end

  context "when saving in the “still-teaching” validation context" do
    it "validates employment_status has been provided" do
      expect(TslrClaim.new).not_to be_valid(:"still-teaching")
      expect(TslrClaim.new(employment_status: :claim_school)).to be_valid(:"still-teaching")
    end
  end

  context "when saving in the “name” validation context" do
    it "validates the presence of full_name" do
      expect(TslrClaim.new).not_to be_valid(:"full-name")
      expect(TslrClaim.new(full_name: "John Kimble")).to be_valid(:"full-name")
    end
  end

  context "when saving in the “address” validation context" do
    it "validates the presence of address_line_1, address_line_3 (i.e. the town or city), and postcode" do
      expect(TslrClaim.new).not_to be_valid(:address)

      valid_address_attributes = {address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "12345"}
      expect(TslrClaim.new(valid_address_attributes)).to be_valid(:address)
    end
    it "validates the length of postcode is not greater than 11" do
      expect(TslrClaim.new(address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M12345 23453WD")).not_to be_valid(:address)
      expect(TslrClaim.new(address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M1 2WD")).to be_valid(:address)
    end
  end

  context "when saving in the “date-of-birth” validation context" do
    it "validates the presence of date_of_birth" do
      expect(TslrClaim.new).not_to be_valid(:"date-of-birth")
      expect(TslrClaim.new(date_of_birth: Date.new(2000, 2, 1))).to be_valid(:"date-of-birth")
    end
  end

  context "when saving in the “teacher-reference-number” validation context" do
    it "validates the presence of teacher_reference_number" do
      expect(TslrClaim.new).not_to be_valid(:"teacher-reference-number")
      expect(TslrClaim.new(teacher_reference_number: "1234567")).to be_valid(:"teacher-reference-number")
    end
  end

  context "when saving a record that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(TslrClaim.new(teacher_reference_number: "1/2/3/4/5/6/7")).to be_valid
      expect(TslrClaim.new(teacher_reference_number: "1/2/3/4/5")).not_to be_valid
      expect(TslrClaim.new(teacher_reference_number: "12/345678")).not_to be_valid
    end
  end

  describe "#teacher_reference_number" do
    let(:claim) { TslrClaim.new(teacher_reference_number: teacher_reference_number) }

    context "when the teacher reference number is stored and contains non digits" do
      let(:teacher_reference_number) { "12\\23 /232 " }
      it "strips out the non digits" do
        claim.save!
        expect(claim.teacher_reference_number).to eql("1223232")
      end
    end

    context "before the teacher reference number is stored" do
      let(:teacher_reference_number) { "12/34567" }
      it "is not modified" do
        expect(claim.teacher_reference_number).to eql("12/34567")
      end
    end
  end

  context "when saving in the “national-insurance-number” validation context" do
    it "validates the presence of national_insurance_number" do
      expect(TslrClaim.new).not_to be_valid(:"national-insurance-number")
      expect(TslrClaim.new(national_insurance_number: "QQ123456C")).to be_valid(:"national-insurance-number")
    end
  end

  context "when saving a record that has a National Insurance number" do
    it "validates that the National Insurance number is in the correct format" do
      expect(TslrClaim.new(national_insurance_number: "12 34 56 78 C")).not_to be_valid
      expect(TslrClaim.new(national_insurance_number: "QQ 11 56 78 DE")).not_to be_valid

      expect(TslrClaim.new(national_insurance_number: "QQ 34 56 78 C")).to be_valid
    end
  end

  describe "#national_insurance_number" do
    it "saves with white space stripped out" do
      claim = TslrClaim.create!(national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  context "when saving in the “email-address” validation context" do
    it "validates the presence of email_address" do
      expect(TslrClaim.new).not_to be_valid(:"email-address")
      expect(TslrClaim.new(email_address: "name@example.tld")).to be_valid(:"email-address")
    end
  end

  context "when saving a record that has a email address" do
    it "validates that the value is in the correct format" do
      expect(TslrClaim.new(email_address: "notan email@address.com")).not_to be_valid
      expect(TslrClaim.new(email_address: "name@example.com")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(TslrClaim.new(email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  describe "#ineligible?" do
    subject { TslrClaim.new(claim_attributes).ineligible? }

    context "with no claim_school" do
      let(:claim_attributes) { {claim_school: nil} }
      it { is_expected.to be false }
    end

    context "with an eligible claim school" do
      let(:claim_attributes) { {claim_school: schools(:penistone_grammar_school)} }
      it { is_expected.to be false }
    end

    context "with an ineligible claim_school" do
      let(:claim_attributes) { {claim_school: schools(:hampstead_school)} }
      it { is_expected.to be true }
    end

    context "when no longer teaching" do
      let(:claim_attributes) { {employment_status: :no_school} }
      it { is_expected.to be true }
    end
  end

  describe "#ineligibility_reason" do
    subject { TslrClaim.new(claim_attributes).ineligibility_reason }

    context "with an ineligible claim_school" do
      let(:claim_attributes) { {claim_school: schools(:hampstead_school)} }
      it { is_expected.to eql :ineligible_claim_school }
    end

    context "when no longer teaching" do
      let(:claim_attributes) { {employment_status: :no_school} }
      it { is_expected.to eql :employed_at_no_school }
    end

    context "when not ineligible" do
      let(:claim_attributes) { {} }
      it { is_expected.to be_nil }
    end
  end

  describe "#employment_status" do
    it "provides an enum that captures the claiment’s employment status" do
      claim = TslrClaim.new

      claim.employment_status = :claim_school
      expect(claim.employed_at_claim_school?).to eq true
      expect(claim.employed_at_different_school?).to eq false
      expect(claim.employed_at_no_school?).to eq false
    end

    it "rejects invalid employment statuses" do
      expect { TslrClaim.new(employment_status: :nonsense) }.to raise_error(ArgumentError)
    end

    context "when set to :claim_school" do
      it "automatically sets current_school to the claim_school" do
        claim = TslrClaim.new(claim_school: schools(:penistone_grammar_school))
        claim.employment_status = :claim_school
        claim.save!

        expect(claim.current_school).to eql(schools(:penistone_grammar_school))
      end
    end

    context "when changed to :different_school" do
      it "automatically resets current_school to nil" do
        claim = TslrClaim.new(claim_school: schools(:penistone_grammar_school), current_school: schools(:penistone_grammar_school), employment_status: :claim_school)
        claim.employment_status = :different_school
        claim.save!

        expect(claim.current_school).to be_nil
      end
    end

    context "when value is :different_school" do
      it "does not automatically reset current_school if employment_status hasn’t changed" do
        claim = TslrClaim.create!(claim_school: schools(:penistone_grammar_school), employment_status: :different_school)
        claim.current_school = schools(:hampstead_school)
        claim.save!

        expect(claim.current_school).to eql(schools(:hampstead_school))
      end
    end
  end

  describe "#claim_school_name" do
    it "returns the name of the claim school" do
      claim = TslrClaim.new(claim_school: schools(:penistone_grammar_school))
      expect(claim.claim_school_name).to eq schools(:penistone_grammar_school).name
    end

    it "does not error if the claim school is not set" do
      expect(TslrClaim.new.claim_school_name).to be_nil
    end
  end

  describe "#page_sequence" do
    let(:tslr_claim) { TslrClaim.new }
    it "returns all the pages in the sequence" do
      expect(tslr_claim.page_sequence).to eq TslrClaim::PAGE_SEQUENCE
    end

    context "when the claimant still works at the school they are claiming against" do
      let(:tslr_claim) do
        TslrClaim.new(claim_school: schools(:penistone_grammar_school), employment_status: :claim_school)
      end

      it "excludes the “current-school” page from the sequence" do
        expect(tslr_claim.page_sequence).not_to include("current-school")
      end
    end
  end
end
