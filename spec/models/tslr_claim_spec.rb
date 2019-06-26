require "rails_helper"

RSpec.describe TslrClaim, type: :model do
  it { should belong_to(:claim_school).optional }
  it { should belong_to(:current_school).optional }

  context "that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(TslrClaim.new(teacher_reference_number: "1/2/3/4/5/6/7")).to be_valid
      expect(TslrClaim.new(teacher_reference_number: "1/2/3/4/5")).not_to be_valid
      expect(TslrClaim.new(teacher_reference_number: "12/345678")).not_to be_valid
    end
  end

  context "that has a email address" do
    it "validates that the value is in the correct format" do
      expect(TslrClaim.new(email_address: "notan email@address.com")).not_to be_valid
      expect(TslrClaim.new(email_address: "name@example.com")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(TslrClaim.new(email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  context "that has a National Insurance number" do
    it "validates that the National Insurance number is in the correct format" do
      expect(TslrClaim.new(national_insurance_number: "12 34 56 78 C")).not_to be_valid
      expect(TslrClaim.new(national_insurance_number: "QQ 11 56 78 DE")).not_to be_valid

      expect(TslrClaim.new(national_insurance_number: "QQ 34 56 78 C")).to be_valid
    end
  end

  context "that has a student loan repayment amount" do
    it "validates that the loan repayment amount is numerical" do
      expect(TslrClaim.new(student_loan_repayment_amount: "don’t know")).not_to be_valid
      expect(TslrClaim.new(student_loan_repayment_amount: "£1,234.56")).to be_valid
    end

    it "validates that the loan repayment is under £99,999" do
      expect(TslrClaim.new(student_loan_repayment_amount: "100000000")).not_to be_valid
      expect(TslrClaim.new(student_loan_repayment_amount: "99999")).to be_valid
    end

    it "validates that the loan repayment a positive number" do
      expect(TslrClaim.new(student_loan_repayment_amount: "-99")).not_to be_valid
      expect(TslrClaim.new(student_loan_repayment_amount: "150")).to be_valid
    end
  end

  context "that has a full name" do
    it "validates the length of name is 200 characters or less" do
      expect(TslrClaim.new(full_name: "Name " * 50)).not_to be_valid
      expect(TslrClaim.new(full_name: "John Kimble")).to be_valid
    end
  end

  context "that has a postcode" do
    it "validates the length of postcode is not greater than 11" do
      expect(TslrClaim.new(address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M12345 23453WD")).not_to be_valid
      expect(TslrClaim.new(address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M1 2WD")).to be_valid
    end
  end

  context "that has a address" do
    it "validates the length of address_line_1 is 100 characters or less" do
      valid_address_attributes = {address_line_1: "123 Main Street" * 25, address_line_3: "Twin Peaks", postcode: "12345"}
      expect(TslrClaim.new(valid_address_attributes)).not_to be_valid
    end
  end

  context "that has bank details" do
    it "validates the format of bank_account_number and bank_sort_code" do
      expect(TslrClaim.new(bank_account_number: "ABC12 34 56 789")).not_to be_valid
      expect(TslrClaim.new(bank_account_number: "12-34-56-78")).to be_valid

      expect(TslrClaim.new(bank_sort_code: "ABC12 34 567")).not_to be_valid
      expect(TslrClaim.new(bank_sort_code: "12 34 56")).to be_valid
    end

    context "on save" do
      it "strips out white space and the “-” character from bank_account_number and bank_sort_code" do
        claim = TslrClaim.new(bank_sort_code: "12 34 56", bank_account_number: "12-34-56-78")
        claim.save!

        expect(claim.bank_sort_code).to eql("123456")
        expect(claim.bank_account_number).to eql("12345678")
      end
    end
  end

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

  context "when saving in the “current-school” validation context" do
    it "it validates the current_school" do
      expect(TslrClaim.new).not_to be_valid(:"current-school")
      expect(TslrClaim.new(current_school: schools(:hampstead_school))).to be_valid(:"current-school")
    end
  end

  context "when saving in the “subjects-taught” validation context" do
    it "validates that a subject has been provided" do
      expect(TslrClaim.new).not_to be_valid(:"subjects-taught")
      expect(TslrClaim.new(eligible_subjects: [:computer_science, :physics])).to be_valid(:"subjects-taught")
    end

    it "does not validate that a subject has been provided when mostly_teaching_eligible_subjects is false" do
      expect(TslrClaim.new).not_to be_valid(:"subjects-taught")
      expect(TslrClaim.new(mostly_teaching_eligible_subjects: false)).to be_valid(:"subjects-taught")
    end
  end

  context "when saving in the “mostly-teaching-eligible-subjects” validation context" do
    it "validates mostly_teaching_eligible_subjects has been provided" do
      expect(TslrClaim.new).not_to be_valid(:"subjects-taught")
      expect(TslrClaim.new(mostly_teaching_eligible_subjects: true)).to be_valid(:"mostly-teaching-eligible-subjects")
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

  context "when saving in the “national-insurance-number” validation context" do
    it "validates the presence of national_insurance_number" do
      expect(TslrClaim.new).not_to be_valid(:"national-insurance-number")
      expect(TslrClaim.new(national_insurance_number: "QQ123456C")).to be_valid(:"national-insurance-number")
    end
  end

  context "when saving in the “student-loan-amount” validation context" do
    it "validates the presence of student_loan_repayment_amount" do
      expect(TslrClaim.new).not_to be_valid(:"student-loan-amount")
      expect(TslrClaim.new(student_loan_repayment_amount: "£1,100")).to be_valid(:"student-loan-amount")
    end
  end

  context "when saving in the “email-address” validation context" do
    it "validates the presence of email_address" do
      expect(TslrClaim.new).not_to be_valid(:"email-address")
      expect(TslrClaim.new(email_address: "name@example.tld")).to be_valid(:"email-address")
    end
  end

  context "when saving in the “bank-details” validation context" do
    it "validates that the bank_account_number and bank_sort_code are present" do
      expect(TslrClaim.new).not_to be_valid(:"bank-details")
      expect(TslrClaim.new(bank_sort_code: "123456", bank_account_number: "87654321")).to be_valid(:"bank-details")
    end
  end

  context "when saving in the “submit” validation context" do
    it "validates the presence of all required fields" do
      expect(TslrClaim.new).not_to be_valid(:submit)
      expect(TslrClaim.new(attributes_for(:tslr_claim, :eligible_and_submittable))).to be_valid(:submit)
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

  describe "#national_insurance_number" do
    it "saves with white space stripped out" do
      claim = TslrClaim.create!(national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  describe "#student_loan_repayment_amount=" do
    it "sets loan repayment amount with monetary characters stripped out" do
      claim = TslrClaim.new
      claim.student_loan_repayment_amount = "£ 5,000.40"
      expect(claim.student_loan_repayment_amount).to eql(5000.40)
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

    context "when taught less than half time in eligible subjects" do
      let(:claim_attributes) { {mostly_teaching_eligible_subjects: false} }
      it { is_expected.to be true }
    end

    context "when taught at least half time in eligible subjects" do
      let(:claim_attributes) { {mostly_teaching_eligible_subjects: true} }
      it { is_expected.to be false }
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

    context "when taught less than half time in eligible subjects" do
      let(:claim_attributes) { {mostly_teaching_eligible_subjects: false} }
      it { is_expected.to eql :not_taught_eligible_subjects_enough }
    end

    context "when not ineligible" do
      let(:claim_attributes) { {} }
      it { is_expected.to be_nil }
    end
  end

  describe "#employment_status" do
    it "provides an enum that captures the claimant’s employment status" do
      claim = TslrClaim.new

      claim.employment_status = :claim_school
      expect(claim.employed_at_claim_school?).to eq true
      expect(claim.employed_at_different_school?).to eq false
      expect(claim.employed_at_no_school?).to eq false
    end

    it "rejects invalid employment statuses" do
      expect { TslrClaim.new(employment_status: :nonsense) }.to raise_error(ArgumentError)
    end

    context "with a persisted record" do
      let(:claim) { TslrClaim.create!(claim_school: schools(:penistone_grammar_school)) }

      it "setting to :claim_school sets the current_school to be the same as claim_school when saved" do
        claim.employment_status = :claim_school
        claim.save!

        expect(claim.current_school).to eql(schools(:penistone_grammar_school))
      end

      it "setting it to :different_school resets the current_school when saved" do
        claim.update!(current_school: schools(:hampstead_school))

        claim.employment_status = :different_school
        claim.save!

        expect(claim.current_school).to be_nil
      end
    end

    context "with an unpersisted record" do
      let(:claim) do
        TslrClaim.new(
          employment_status: :different_school,
          claim_school: schools(:penistone_grammar_school),
          current_school: schools(:hampstead_school)
        )
      end

      it "doesn’t reset the current_school when saved" do
        claim.save!
        expect(claim.current_school).to eq(schools(:hampstead_school))
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

  describe "#submit!" do
    around do |example|
      freeze_time { example.run }
    end

    before { tslr_claim.submit! }

    context "when the claim is eligible and submittable" do
      let(:tslr_claim) { create(:tslr_claim, :eligible_and_submittable) }

      it "sets submitted_at to now" do
        expect(tslr_claim.submitted_at).to eq Time.zone.now
      end

      it "generates a reference" do
        expect(tslr_claim.reference).to_not eq nil
      end

      context "when a claim with the same reference already exists" do
        let(:reference) { "12345678" }
        let!(:other_claim) { create(:tslr_claim, :eligible_and_submittable, reference: reference) }

        before do
          expect(Reference).to receive(:new).once.and_return(double(to_s: reference), double(to_s: "87654321"))
          tslr_claim.submit!
        end

        it "generates a unique reference" do
          expect(tslr_claim.reference).to eq("87654321")
        end
      end
    end

    context "when the claim is eligible but unsubmittable" do
      let(:tslr_claim) { create(:tslr_claim, :eligible_but_unsubmittable) }

      it "doesn't set submitted_at" do
        expect(tslr_claim.submitted_at).to be_nil
      end

      it "doesn't generate a reference" do
        expect(tslr_claim.reference).to eq nil
      end
    end

    context "when the claim is ineligible" do
      let(:tslr_claim) { create(:tslr_claim, :eligible_and_submittable, mostly_teaching_eligible_subjects: false) }

      it "doesn't set submitted_at" do
        expect(tslr_claim.submitted_at).to be_nil
      end

      it "doesn't generate a reference" do
        expect(tslr_claim.reference).to eq nil
      end

      it "adds an error" do
        expect(tslr_claim.errors.messages[:base]).to include("You must have spent at least half your time teaching an eligible subject.")
      end
    end
  end

  describe "submitted" do
    let!(:submitted_claims) { create_list(:tslr_claim, 5, :submitted) }
    let!(:unsubmitted_claims) { create_list(:tslr_claim, 2, :eligible_and_submittable) }

    it "returns submitted claims" do
      expect(subject.class.submitted).to match_array(submitted_claims)
    end
  end
end
