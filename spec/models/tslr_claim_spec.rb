require "rails_helper"

RSpec.describe TslrClaim, type: :model do
  context "that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(build(:tslr_claim, teacher_reference_number: "1/2/3/4/5/6/7")).to be_valid
      expect(build(:tslr_claim, teacher_reference_number: "1/2/3/4/5")).not_to be_valid
      expect(build(:tslr_claim, teacher_reference_number: "12/345678")).not_to be_valid
    end
  end

  context "that has a email address" do
    it "validates that the value is in the correct format" do
      expect(build(:tslr_claim, email_address: "notan email@address.com")).not_to be_valid
      expect(build(:tslr_claim, email_address: "name@example.com")).to be_valid
      expect(build(:tslr_claim, email_address: "")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(build(:tslr_claim, email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  context "that has a National Insurance number" do
    it "validates that the National Insurance number is in the correct format" do
      expect(build(:tslr_claim, national_insurance_number: "12 34 56 78 C")).not_to be_valid
      expect(build(:tslr_claim, national_insurance_number: "QQ 11 56 78 DE")).not_to be_valid

      expect(build(:tslr_claim, national_insurance_number: "QQ 34 56 78 C")).to be_valid
    end
  end

  context "that has a student loan repayment amount" do
    it "validates that the loan repayment amount is numerical" do
      expect(build(:tslr_claim, student_loan_repayment_amount: "don’t know")).not_to be_valid
      expect(build(:tslr_claim, student_loan_repayment_amount: "£1,234.56")).to be_valid
    end

    it "validates that the loan repayment is under £99,999" do
      expect(build(:tslr_claim, student_loan_repayment_amount: "100000000")).not_to be_valid
      expect(build(:tslr_claim, student_loan_repayment_amount: "99999")).to be_valid
    end

    it "validates that the loan repayment a positive number" do
      expect(build(:tslr_claim, student_loan_repayment_amount: "-99")).not_to be_valid
      expect(build(:tslr_claim, student_loan_repayment_amount: "150")).to be_valid
    end
  end

  context "that has a full name" do
    it "validates the length of name is 200 characters or less" do
      expect(build(:tslr_claim, full_name: "Name " * 50)).not_to be_valid
      expect(build(:tslr_claim, full_name: "John Kimble")).to be_valid
    end
  end

  context "that has a postcode" do
    it "validates the length of postcode is not greater than 11" do
      expect(build(:tslr_claim, address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M12345 23453WD")).not_to be_valid
      expect(build(:tslr_claim, address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "M1 2WD")).to be_valid
    end
  end

  context "that has a address" do
    it "validates the length of address_line_1 is 100 characters or less" do
      valid_address_attributes = {address_line_1: "123 Main Street" * 25, address_line_3: "Twin Peaks", postcode: "12345"}
      expect(build(:tslr_claim, valid_address_attributes)).not_to be_valid
    end
  end

  context "that has bank details" do
    it "validates the format of bank_account_number and bank_sort_code" do
      expect(build(:tslr_claim, bank_account_number: "ABC12 34 56 789")).not_to be_valid
      expect(build(:tslr_claim, bank_account_number: "12-34-56-78")).to be_valid

      expect(build(:tslr_claim, bank_sort_code: "ABC12 34 567")).not_to be_valid
      expect(build(:tslr_claim, bank_sort_code: "12 34 56")).to be_valid
    end

    context "on save" do
      it "strips out white space and the “-” character from bank_account_number and bank_sort_code" do
        claim = build(:tslr_claim, bank_sort_code: "12 34 56", bank_account_number: "12-34-56-78")
        claim.save!

        expect(claim.bank_sort_code).to eql("123456")
        expect(claim.bank_account_number).to eql("12345678")
      end
    end
  end

  context "that has a student loan plan" do
    it "validates the plan" do
      expect(build(:tslr_claim, student_loan_plan: StudentLoans::PLAN_1)).to be_valid

      expect { build(:tslr_claim, student_loan_plan: "plan_42") }.to raise_error(ArgumentError)
    end
  end

  it "is not submittable without a value for the student_loan_plan present" do
    expect(build(:tslr_claim, :submittable, student_loan_plan: nil)).not_to be_valid(:submit)
    expect(build(:tslr_claim, :submittable, student_loan_plan: TslrClaim::NO_STUDENT_LOAN)).to be_valid(:submit)
  end

  it "is submittable with optional student loan questions not answered" do
    claim = build(
      :tslr_claim,
      :submittable,
      has_student_loan: false,
      student_loan_plan: TslrClaim::NO_STUDENT_LOAN,
      student_loan_country: nil,
      student_loan_courses: nil,
      student_loan_start_date: nil
    )

    expect(claim).to be_valid(:submit)
  end

  it "triggers validations on the eligibility appropriate to the context" do
    claim = build(:tslr_claim)

    expect(claim).not_to be_valid(:"qts-year")
    expect(claim.errors.values).to include(["Select the academic year you were awarded qualified teacher status"])
  end

  context "when saving in the “gender” validation context" do
    it "validates the presence of gender" do
      expect(build(:tslr_claim)).not_to be_valid(:gender)
      expect(build(:tslr_claim, payroll_gender: :male)).to be_valid(:gender)
    end
  end

  context "when saving in the “name” validation context" do
    it "validates the presence of full_name" do
      expect(build(:tslr_claim)).not_to be_valid(:"full-name")
      expect(build(:tslr_claim, full_name: "John Kimble")).to be_valid(:"full-name")
    end
  end

  context "when saving in the “address” validation context" do
    it "validates the presence of address_line_1, address_line_3 (i.e. the town or city), and postcode" do
      expect(build(:tslr_claim)).not_to be_valid(:address)

      valid_address_attributes = {address_line_1: "123 Main Street", address_line_3: "Twin Peaks", postcode: "12345"}
      expect(build(:tslr_claim, valid_address_attributes)).to be_valid(:address)
    end
  end

  context "when saving in the “date-of-birth” validation context" do
    it "validates the presence of date_of_birth" do
      expect(build(:tslr_claim)).not_to be_valid(:"date-of-birth")
      expect(build(:tslr_claim, date_of_birth: Date.new(2000, 2, 1))).to be_valid(:"date-of-birth")
    end
  end

  context "when saving in the “teacher-reference-number” validation context" do
    it "validates the presence of teacher_reference_number" do
      expect(build(:tslr_claim)).not_to be_valid(:"teacher-reference-number")
      expect(build(:tslr_claim, teacher_reference_number: "1234567")).to be_valid(:"teacher-reference-number")
    end
  end

  context "when saving in the “national-insurance-number” validation context" do
    it "validates the presence of national_insurance_number" do
      expect(build(:tslr_claim)).not_to be_valid(:"national-insurance-number")
      expect(build(:tslr_claim, national_insurance_number: "QQ123456C")).to be_valid(:"national-insurance-number")
    end
  end

  context "when saving in the “student-loan” validation context" do
    it "validates the presence of student_loan" do
      expect(build(:tslr_claim)).not_to be_valid(:"student-loan")
      expect(build(:tslr_claim, has_student_loan: true)).to be_valid(:"student-loan")
      expect(build(:tslr_claim, has_student_loan: false)).to be_valid(:"student-loan")
    end
  end

  context "when saving in the “student-loan-country” validation context" do
    it "validates the presence of student_loan_country" do
      expect(build(:tslr_claim)).not_to be_valid(:"student-loan-country")
      expect(build(:tslr_claim, student_loan_country: :england)).to be_valid(:"student-loan-country")
    end
  end

  context "when saving in the “student-loan-how-many-courses” validation context" do
    it "validates the presence of the student_loan_how_many_courses" do
      expect(build(:tslr_claim)).not_to be_valid(:"student-loan-how-many-courses")
      expect(build(:tslr_claim, student_loan_courses: :one_course)).to be_valid(:"student-loan-how-many-courses")
    end
  end

  context "when saving in the “student-loan-start-date” validation context" do
    it "validates the presence of the student_loan_how_many_courses" do
      expect(build(:tslr_claim)).not_to be_valid(:"student-loan-start-date")
      expect(build(:tslr_claim, student_loan_start_date: StudentLoans::BEFORE_1_SEPT_2012)).to be_valid(:"student-loan-start-date")
    end
  end

  context "when saving in the “student-loan-amount” validation context" do
    it "validates the presence of student_loan_repayment_amount" do
      expect(build(:tslr_claim)).not_to be_valid(:"student-loan-amount")
      expect(build(:tslr_claim, student_loan_repayment_amount: "£1,100")).to be_valid(:"student-loan-amount")
    end
  end

  context "when saving in the “email-address” validation context" do
    it "validates the presence of email_address" do
      expect(build(:tslr_claim)).not_to be_valid(:"email-address")
      expect(build(:tslr_claim, email_address: "name@example.tld")).to be_valid(:"email-address")
    end
  end

  context "when saving in the “bank-details” validation context" do
    it "validates that the bank_account_number and bank_sort_code are present" do
      expect(build(:tslr_claim)).not_to be_valid(:"bank-details")
      expect(build(:tslr_claim, bank_sort_code: "123456", bank_account_number: "87654321")).to be_valid(:"bank-details")
    end
  end

  context "when saving in the “submit” validation context" do
    it "validates the claim is in a submittable state" do
      expect(build(:tslr_claim)).not_to be_valid(:submit)
      expect(build(:tslr_claim, :submittable)).to be_valid(:submit)
    end

    it "validates the claim’s eligibility" do
      ineligible_claim = build(:tslr_claim, :submittable)
      ineligible_claim.eligibility.mostly_teaching_eligible_subjects = false

      expect(ineligible_claim).not_to be_valid(:submit)
      expect(ineligible_claim.errors[:base]).to include(I18n.t("activerecord.errors.messages.not_taught_eligible_subjects_enough"))
    end
  end

  describe "#teacher_reference_number" do
    let(:claim) { build(:tslr_claim, teacher_reference_number: teacher_reference_number) }

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
      claim = create(:tslr_claim, national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  describe "#student_loan_repayment_amount=" do
    it "sets loan repayment amount with monetary characters stripped out" do
      claim = build(:tslr_claim)
      claim.student_loan_repayment_amount = "£ 5,000.40"
      expect(claim.student_loan_repayment_amount).to eql(5000.40)
    end
  end

  describe "#ineligible?" do
    subject { build(:tslr_claim, claim_attributes).ineligible? }

    context "with an ineligible QTS award year" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, qts_award_year: "before_2013")} }
      it { is_expected.to be true }
    end

    context "with an eligible QTS award year" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, qts_award_year: "2013_2014")} }
      it { is_expected.to be false }
    end

    context "with no claim_school" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, claim_school: nil)} }
      it { is_expected.to be false }
    end

    context "with an eligible claim school" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, claim_school: schools(:penistone_grammar_school))} }
      it { is_expected.to be false }
    end

    context "with an ineligible claim_school" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, claim_school: schools(:hampstead_school))} }
      it { is_expected.to be true }
    end

    context "when no longer teaching" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, employment_status: :no_school)} }
      it { is_expected.to be true }
    end

    context "when taught less than half time in eligible subjects" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, mostly_teaching_eligible_subjects: false)} }
      it { is_expected.to be true }
    end

    context "when taught at least half time in eligible subjects" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, mostly_teaching_eligible_subjects: true)} }
      it { is_expected.to be false }
    end
  end

  describe "#ineligibility_reason" do
    subject { build(:tslr_claim, claim_attributes).ineligibility_reason }

    context "with an ineligible qts_award_year" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, qts_award_year: "before_2013")} }
      it { is_expected.to eql :ineligible_qts_award_year }
    end

    context "with an ineligible claim_school" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, claim_school: schools(:hampstead_school))} }
      it { is_expected.to eql :ineligible_claim_school }
    end

    context "when no longer teaching" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, employment_status: :no_school)} }
      it { is_expected.to eql :employed_at_no_school }
    end

    context "when taught less than half time in eligible subjects" do
      let(:claim_attributes) { {eligibility: build(:student_loans_eligibility, mostly_teaching_eligible_subjects: false)} }
      it { is_expected.to eql :not_taught_eligible_subjects_enough }
    end

    context "when not ineligible" do
      let(:claim_attributes) { {} }
      it { is_expected.to be_nil }
    end
  end

  describe "#student_loan_country" do
    it "captures the country the student loan was received in" do
      claim = build(:tslr_claim, student_loan_country: :england)
      expect(claim.student_loan_country).to eq("england")
    end

    it "rejects invalid countries" do
      expect { build(:tslr_claim, student_loan_country: :brazil) }.to raise_error(ArgumentError)
    end
  end

  describe "#student_loan_how_many_courses" do
    it "captures how many courses" do
      claim = build(:tslr_claim, student_loan_courses: :one_course)
      expect(claim.student_loan_courses).to eq("one_course")
    end

    it "rejects invalid responses" do
      expect { build(:tslr_claim, student_loan_courses: :one_hundred_courses) }.to raise_error(ArgumentError)
    end
  end

  describe "#no_student_loan?" do
    it "returns true if the claim has no student loan" do
      expect(build(:tslr_claim, has_student_loan: false).no_student_loan?).to eq true
      expect(build(:tslr_claim, has_student_loan: true).no_student_loan?).to eq false
    end
  end

  describe "#student_loan_country_with_one_plan?" do
    it "returns true when the student_loan_country is one with only a single student loan plan" do
      expect(build(:tslr_claim).student_loan_country_with_one_plan?).to eq false

      StudentLoans::PLAN_1_COUNTRIES.each do |country|
        expect(build(:tslr_claim, student_loan_country: country).student_loan_country_with_one_plan?).to eq true
      end
    end
  end

  describe "#submit!" do
    around do |example|
      freeze_time { example.run }
    end

    context "when the claim is submittable" do
      let(:tslr_claim) { create(:tslr_claim, :submittable) }

      before { tslr_claim.submit! }

      it "sets submitted_at to now" do
        expect(tslr_claim.submitted_at).to eq Time.zone.now
      end

      it "generates a reference" do
        expect(tslr_claim.reference).to_not eq nil
      end
    end

    context "when a Reference clash with an existing claim occurs" do
      let(:tslr_claim) { create(:tslr_claim, :submittable) }

      before do
        other_claim = create(:tslr_claim, :submittable, reference: "12345678")
        expect(Reference).to receive(:new).once.and_return(double(to_s: other_claim.reference), double(to_s: "87654321"))
        tslr_claim.submit!
      end

      it "generates a unique reference" do
        expect(tslr_claim.reference).to eq("87654321")
      end
    end

    context "when the claim is ineligible" do
      let(:ineligible_eligibility) { build(:student_loans_eligibility, :submittable, mostly_teaching_eligible_subjects: false) }
      let(:tslr_claim) { create(:tslr_claim, :submittable, eligibility: ineligible_eligibility) }

      before { tslr_claim.submit! }

      it "doesn't set submitted_at" do
        expect(tslr_claim.submitted_at).to be_nil
      end

      it "doesn't generate a reference" do
        expect(tslr_claim.reference).to eq nil
      end

      it "adds an error" do
        expect(tslr_claim.errors.messages[:base]).to include(I18n.t("activerecord.errors.messages.not_taught_eligible_subjects_enough"))
      end
    end

    context "when the claim has already been submitted" do
      let(:tslr_claim) { create(:tslr_claim, :submitted, submitted_at: 2.days.ago) }

      it "returns false" do
        expect(tslr_claim.submit!).to eq false
      end

      it "doesn't change the reference number" do
        expect { tslr_claim.submit! }.not_to(change { tslr_claim.reference })
      end

      it "doesn't change the submitted_at" do
        expect { tslr_claim.submit! }.not_to(change { tslr_claim.submitted_at })
      end
    end
  end

  describe "submitted" do
    let!(:submitted_claims) { create_list(:tslr_claim, 5, :submitted) }
    let!(:unsubmitted_claims) { create_list(:tslr_claim, 2, :submittable) }

    it "returns submitted claims" do
      expect(subject.class.submitted).to match_array(submitted_claims)
    end
  end

  describe "#submittable?" do
    it "returns true when the claim is valid and has not been submitted" do
      claim = build(:tslr_claim, :submittable)

      expect(claim.submittable?).to eq true
    end
    it "returns false when it has already been submitted" do
      claim = build(:tslr_claim, :submitted)

      expect(claim.submittable?).to eq false
    end
  end
end
