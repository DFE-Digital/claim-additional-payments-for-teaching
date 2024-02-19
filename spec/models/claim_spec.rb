require "rails_helper"

RSpec.describe Claim, type: :model do
  it "validates academic years are formated like '2020/2021'" do
    expect(build(:claim, academic_year: "2022/2023")).to be_valid
    expect(build(:claim, academic_year: "2020-2021")).not_to be_valid
  end

  context "that has a teacher_reference_number" do
    it "validates the length of the teacher reference number" do
      expect(build(:claim, teacher_reference_number: "1/2/3/4/5/6/7")).to be_valid
      expect(build(:claim, teacher_reference_number: "1/2/3/4/5")).not_to be_valid
      expect(build(:claim, teacher_reference_number: "12/345678")).not_to be_valid
    end
  end

  context "that has a email address" do
    it "validates that the value is in the correct format" do
      expect(build(:claim, email_address: "notan email@address.com")).not_to be_valid
      expect(build(:claim, email_address: "name@example")).not_to be_valid
      expect(build(:claim, email_address: "name@example.com")).to be_valid
      expect(build(:claim, email_address: "")).to be_valid
    end

    it "checks that the email address in not longer than 256 characters" do
      expect(build(:claim, email_address: "#{"e" * 256}@example.com")).not_to be_valid
    end
  end

  context "that has a National Insurance number" do
    it "validates that the National Insurance number is in the correct format" do
      expect(build(:claim, national_insurance_number: "12 34 56 78 C")).not_to be_valid
      expect(build(:claim, national_insurance_number: "QQ 11 56 78 DE")).not_to be_valid

      expect(build(:claim, national_insurance_number: "QQ 34 56 78 C")).to be_valid
    end
  end

  context "that has a postcode" do
    it "validates the length of postcode is not greater than 11" do
      expect(build(:claim, postcode: "M12345 23453WD")).not_to be_valid
      expect(build(:claim, postcode: "M1 2WD")).to be_valid
    end
  end

  context "that has an address" do
    it "validates the length of each address line is not greater than 100 characters" do
      %i[address_line_1 address_line_2 address_line_3 address_line_4].each do |attribute_name|
        expect(build(:claim, attribute_name => "X" + "ABCD" * 25)).not_to be_valid
        expect(build(:claim, attribute_name => "ABCD" * 25)).to be_valid
      end
    end
  end

  context "that has bank details" do
    let(:claim) { build(:claim, policy: Policies::EarlyCareerPayments) }

    it "validates which type of payment account was specified" do
      expect(claim).not_to be_valid(:"bank-or-building-society")

      expect { claim.bank_or_building_society = "paypal" }.to raise_error(ArgumentError)

      claim.bank_or_building_society = :building_society

      expect(claim).to be_valid(:"bank-or-building-society")
    end

    it "does not validate which type of payment account was specified" do
      expect { claim.bank_or_building_society = "visa" }.to raise_error(ArgumentError)
    end

    it "validates the format of bank_account_number and bank_sort_code" do
      expect(build(:claim, bank_account_number: "ABC12 34 56 789")).not_to be_valid
      expect(build(:claim, bank_account_number: "12-34-56-78-90")).not_to be_valid
      expect(build(:claim, bank_account_number: "12-34-56-78")).to be_valid
      expect(build(:claim, bank_account_number: "12-34-56")).not_to be_valid

      expect(build(:claim, bank_sort_code: "ABC12 34 567")).not_to be_valid
      expect(build(:claim, bank_sort_code: "12 34 56")).to be_valid
    end

    it "validates the format of the building society roll number" do
      expect(build(:claim, building_society_roll_number: "CXJ-K6 897/98X")).to be_valid
      expect(build(:claim, building_society_roll_number: "123456789/ABCD")).to be_valid
      expect(build(:claim, building_society_roll_number: "123456789")).to be_valid

      expect(build(:claim, building_society_roll_number: "123456789/ABC.CD-EFGH ")).not_to be_valid
      expect(build(:claim, building_society_roll_number: "123456789/*****")).not_to be_valid
    end

    context "on save" do
      it "strips out white space and the “-” character from bank_account_number and bank_sort_code" do
        claim = build(:claim, bank_sort_code: "12 34 56", bank_account_number: "12-34-56-78")
        claim.save!

        expect(claim.bank_sort_code).to eql("123456")
        expect(claim.bank_account_number).to eql("12345678")
      end

      it "strips spaces from and upcases the National Insurance number" do
        claim = build(:claim, national_insurance_number: "qq 34 56 78 c")
        claim.save!

        expect(claim.national_insurance_number).to eq("QQ345678C")
      end
    end
  end

  context "that has a student loan plan" do
    it "validates the plan" do
      expect(build(:claim, student_loan_plan: StudentLoan::PLAN_1)).to be_valid
      expect(build(:claim, student_loan_plan: nil)).to be_valid

      expect(build(:claim, student_loan_plan: "plan_42")).not_to be_valid
    end
  end

  it "is not submittable without a value for the student_loan_plan present" do
    expect(build(:claim, :submittable, student_loan_plan: nil)).not_to be_valid(:submit)
    expect(build(:claim, :submittable, student_loan_plan: Claim::NO_STUDENT_LOAN)).to be_valid(:submit)
  end

  it "is submittable with optional student loan questions not answered" do
    claim = build(
      :claim,
      :submittable,
      has_student_loan: false,
      student_loan_plan: Claim::NO_STUDENT_LOAN,
      student_loan_country: nil,
      student_loan_courses: nil,
      student_loan_start_date: nil,
      has_masters_doctoral_loan: false
    )

    expect(claim).to be_valid(:submit)
  end

  context "with an open school" do
    it "is submittable" do
      claim = build(:claim, :submittable)
      claim.eligibility.current_school = build(:school, :open)
      expect(claim).to be_valid(:submit)
    end
  end

  context "with no school" do
    it "is not submittable" do
      claim = build(:claim, :submittable)
      claim.eligibility.current_school = nil
      expect(claim).not_to be_valid(:submit)
    end
  end

  context "with a closed school" do
    it "is not submittable" do
      claim = build(:claim, :submittable)
      claim.eligibility.current_school = build(:school, :closed)
      expect(claim).not_to be_valid(:submit)
    end
  end

  context "with student loans policy eligibility" do
    let(:claim) { build(:claim, policy: StudentLoans) }

    # Tests a single attribute, possibly should test multiple attributes
    it "validates eligibility" do
      expect(claim).not_to be_valid(:"qts-year")
      expect(claim.errors.first.message).to eq("Select when you completed your initial teacher training")
    end
  end

  context "with early-career payments policy eligibility" do
    let(:claim) { build(:claim, policy: Policies::EarlyCareerPayments) }

    # Tests a single attribute, possibly should test multiple attributes
    it "validates eligibility" do
      expect(claim).not_to be_valid(:"nqt-in-academic-year-after-itt")
      expect(claim.errors.first.message).to eq("Select yes if you are currently teaching as a qualified teacher")
    end
  end

  context "when saving in the “gender” validation context" do
    it "validates the presence of gender" do
      expect(build(:claim)).not_to be_valid(:gender)
      expect(build(:claim, payroll_gender: :male)).to be_valid(:gender)
    end
  end

  context "when validating in the 'personal-details' context" do
    describe "with first_name" do
      it "is not valid without a value between 1 and 100 characters" do
        expect(build(:claim, policy: Policies::EarlyCareerPayments)).not_to be_valid(:"personal-details")
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, first_name: "")).not_to be_valid(:"personal-details")
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, first_name: "A" * 101)).not_to be_valid(:"personal-details")
      end

      it "is valid when is between 1 and 100 characters in length" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments)).to be_valid(:"personal-details")
      end

      it "allows user to enter ' in their surname and joins the first name and surname together" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, first_name: "O'Brian", surname: "Isambard")).to be_valid(:"personal-details")
      end
    end

    describe "with middle names" do
      it "validates the length of middle name is 61 characters or less" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, middle_name: "ab" * 31)).not_to be_valid(:"personal-details")
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, middle_name: "a" * 61)).to be_valid(:"personal-details")
        expect(build(:claim, middle_name: "Arnold")).to be_valid
      end

      it "allows user to enter ' in their middle name and joins the first name and surname together" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, first_name: "Isambard", middle_name: "O’Hara")).to be_valid(:"personal-details")
      end
    end

    describe "with surname" do
      it "is not valid without a value between 1 and 100 characters" do
        expect(build(:claim, policy: Policies::EarlyCareerPayments)).not_to be_valid(:"personal-details")
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, surname: "")).not_to be_valid(:"personal-details")
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, surname: "A" * 101)).not_to be_valid(:"personal-details")
      end

      it "is valid when is between 1 and 100 characters in length" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, surname: "A")).to be_valid(:"personal-details")
      end

      it "allows user to enter ' in their middle_name and includes a surname when present" do
        expect(build(:claim, :submittable, policy: Policies::EarlyCareerPayments, first_name: "Isambard", middle_name: "Brunel", surname: "O’Hara")).to be_valid(:"personal-details")
      end
    end
  end

  context "when saving in the “address” validation context" do
    it "validates the presence of address_line_1 and postcode" do
      expect(build(:claim)).not_to be_valid(:address)

      valid_address_attributes = {address_line_1: "123 Main Street", address_line_3: "City", address_line_4: "County", postcode: "PE11 3EW"}
      expect(build(:claim, valid_address_attributes)).to be_valid(:address)
    end
  end

  context "with early-career payments policy validates 'date_of_birth' in the 'personal-details' context" do
    it "is on or after 1st Jan 1900" do
      expect(build(:claim, first_name: "Martha", surname: "Stevens", national_insurance_number: "AB755003B", policy: Policies::EarlyCareerPayments, date_of_birth: Date.new(1899, 12, 31))).not_to be_valid(:"personal-details")
    end

    it "must be in the past" do
      expect(build(:claim, first_name: "Matthew", surname: "Cook", national_insurance_number: "EF755003B", policy: Policies::EarlyCareerPayments, date_of_birth: Date.today + 5)).not_to be_valid(:"personal-details")
    end

    it "must include day/month/year" do
      expect { build(:claim, first_name: "Wayne", surname: "Lee", national_insurance_number: "TX551003B", policy: Policies::EarlyCareerPayments, date_of_birth: Date.new(2021, 31)) }.to raise_error(ArgumentError)
    end

    it "must be in the right format" do
      expect { build(:claim, first_name: "Hannah", surname: "Clay-Simmones", national_insurance_number: "TX661003C", policy: Policies::EarlyCareerPayments, date_of_birth: Date.new(1998, 14, 12)) }.to raise_error("invalid date")
    end
  end

  context "with student loans policy validates 'date_of_birth' in the 'personal-details' context" do
    let(:claim) do
      build(
        :claim,
        first_name: "Molly",
        surname: "Ringwald",
        national_insurance_number: "EF755003B",
        policy: StudentLoans,
        date_of_birth: date_of_birth
      )
    end

    context "when date is on or after 1st Jan 1900" do
      let(:date_of_birth) { Date.new(1899, 12, 31) }

      it "is invalid" do
        expect(claim).not_to be_valid(:"personal-details")
        expect(claim.errors.messages[:date_of_birth]).to eq(["Year must be after 1900"])
      end
    end

    context "when the year has fewer than 4 digits" do
      let(:date_of_birth) { Date.new(999, 12, 31) }

      it "is invalid" do
        expect(claim).not_to be_valid(:"personal-details")
        expect(claim.errors.messages[:date_of_birth]).to eq(["Year must include 4 numbers"])
      end
    end

    context "when date is in the future" do
      let(:date_of_birth) { Date.today + 5 }

      it "is invalid" do
        expect(claim).not_to be_valid(:"personal-details")
        expect(claim.errors.messages[:date_of_birth]).to eq(["Date of birth must be in the past"])
      end
    end

    context "when date is missing" do
      let(:date_of_birth) { nil }

      it "is invalid" do
        expect(claim).not_to be_valid(:"personal-details")
        expect(claim.errors.messages[:date_of_birth]).to eq(["Enter your date of birth"])
      end
    end

    it "must include day/month/year" do
      expect { build(:claim, first_name: "Grace", surname: "Hollywell", national_insurance_number: "TX668003B", policy: StudentLoans, date_of_birth: Date.new(2021, 31)) }.to raise_error(ArgumentError)
    end

    it "must be in the right format" do
      expect { build(:claim, first_name: "Lara", surname: "Royce-Simmones", national_insurance_number: "TX113203D", policy: StudentLoans, date_of_birth: Date.new(1994, 14, 10)) }.to raise_error("invalid date")
    end
  end

  context "when saving in the “teacher-reference-number” validation context" do
    it "validates the presence of teacher_reference_number" do
      expect(build(:claim)).not_to be_valid(:"teacher-reference-number")
      expect(build(:claim, teacher_reference_number: "1234567")).to be_valid(:"teacher-reference-number")
    end
  end

  context "when saving in the “personal-details” validation context" do
    it "validates the presence of national_insurance_number" do
      expect(build(:claim)).not_to be_valid(:"personal-details")
      expect(build(:claim,
        national_insurance_number: "QQ123456C",
        first_name: "Walter",
        surname: "Somersmith",
        date_of_birth: Date.new(1987, 2, 2))).to be_valid(:"personal-details")
    end
  end

  context "when saving in the “student-loan” validation context" do
    it "validates the presence of student_loan" do
      expect(build(:claim)).not_to be_valid(:"student-loan")
      expect(build(:claim, has_student_loan: true)).to be_valid(:"student-loan")
      expect(build(:claim, has_student_loan: false)).to be_valid(:"student-loan")
    end
  end

  context "when saving in the “student-loan-country” validation context" do
    it "validates the presence of student_loan_country" do
      expect(build(:claim)).not_to be_valid(:"student-loan-country")
      expect(build(:claim, student_loan_country: :england)).to be_valid(:"student-loan-country")
    end
  end

  context "when saving in the “student-loan-how-many-courses” validation context" do
    it "validates the presence of the student_loan_how_many_courses" do
      expect(build(:claim)).not_to be_valid(:"student-loan-how-many-courses")
      expect(build(:claim, student_loan_courses: :one_course)).to be_valid(:"student-loan-how-many-courses")
    end
  end

  context "when saving in the “student-loan-start-date” validation context" do
    it "validates the presence of the student_loan_start_date" do
      expect(build(:claim, student_loan_courses: :one_course)).not_to be_valid(:"student-loan-start-date")
      expect(build(:claim, student_loan_start_date: StudentLoan::BEFORE_1_SEPT_2012)).to be_valid(:"student-loan-start-date")
    end

    it "the validation error message is pluralized or not based on student_loan_how_many_courses" do
      claim = build(:claim, student_loan_courses: :one_course)
      claim.valid?(:"student-loan-start-date")
      expect(claim.errors[:student_loan_start_date]).to eq [I18n.t("validation_errors.student_loan_start_date.#{claim.student_loan_courses}")]

      claim = build(:claim, student_loan_courses: :two_or_more_courses)
      claim.valid?(:"student-loan-start-date")
      expect(claim.errors[:student_loan_start_date]).to eq [I18n.t("validation_errors.student_loan_start_date.#{claim.student_loan_courses}")]
    end
  end

  context "when saving in the “masters-doctoral-loan” validation context" do
    it "validates the presence of postgraduate masters and/or doctoral loan(s)" do
      expect(build(:claim)).not_to be_valid(:"masters-doctoral-loan")
      expect(build(:claim, has_masters_doctoral_loan: true)).to be_valid(:"masters-doctoral-loan")
      expect(build(:claim, has_masters_doctoral_loan: false)).to be_valid(:"masters-doctoral-loan")
    end
  end

  context "with early-career payments policy" do
    describe "when saving in the 'postgraduate_masters_loan' context" do
      let(:claim) { build(:claim, :submittable, postgraduate_masters_loan: nil, policy: Policies::EarlyCareerPayments) }

      context "with claim having a masters and/or doctoral loan(s)" do
        it "is not valid without a value for 'postgraduate_masters_loan'" do
          expect(claim.has_masters_doctoral_loan?).to eq false
          expect(claim).not_to be_valid(:"masters-loan")
          expect(build(:claim, postgraduate_masters_loan: true)).to be_valid(:"masters-loan")
          expect(build(:claim, postgraduate_masters_loan: false)).to be_valid(:"masters-loan")
        end
      end

      context "with claim having no masters and/or doctoral loan(s)" do
        it "is valid without a value for 'postgraduate_masters_loan'" do
          subject.validate(on: :"masters-loan")
          expect(subject.errors[:"masters-loan"]).to be_empty
        end
      end
    end

    describe "when saving in the 'postgraduate_doctoral_loan' context" do
      let(:claim) { build(:claim, :submittable, postgraduate_doctoral_loan: nil, policy: Policies::EarlyCareerPayments) }

      context "with claim having a masters and/or doctoral loan(s)" do
        it "is not valid without a value for 'postgraduate_doctoral_loan'" do
          expect(claim.has_masters_doctoral_loan?).to eql false
          expect(claim).not_to be_valid(:"doctoral-loan")
          expect(build(:claim, postgraduate_doctoral_loan: true)).to be_valid(:"doctoral-loan")
          expect(build(:claim, postgraduate_doctoral_loan: false)).to be_valid(:"doctoral-loan")
        end
      end

      context "with claim having no masters and/or doctoral loan(s)" do
        it "is valid without a value for 'postgraduate_doctoral_loan'" do
          subject.validate(on: :"doctoral-loan")
          expect(subject.errors[:"doctoral-loan"]).to be_empty
        end
      end
    end
  end

  context "with student loans policy" do
    describe "when saving in the 'postgraduate_masters_loan' context" do
      let(:claim) { build(:claim, :submittable, postgraduate_masters_loan: nil, policy: StudentLoans) }

      context "with claim having a masters and/or doctoral loan(s)" do
        it "is not valid without a value for 'postgraduate_masters_loan'" do
          expect(claim.has_masters_doctoral_loan?).to eql false
          expect(claim).not_to be_valid(:"masters-loan")
          expect(build(:claim, postgraduate_masters_loan: true)).to be_valid(:"masters-loan")
          expect(build(:claim, postgraduate_masters_loan: false)).to be_valid(:"masters-loan")
        end
      end

      context "with claim having no masters and/or doctoral loan(s)" do
        it "is valid without a value for 'postgraduate_masters_loan'" do
          subject.validate(on: :"masters-loan")
          expect(subject.errors[:"masters-loan"]).to be_empty
        end
      end
    end

    describe "when saving in the 'postgraduate_doctoral_loan' context" do
      let(:claim) { build(:claim, :submittable, postgraduate_doctoral_loan: nil, policy: StudentLoans) }

      context "with claim having a masters and/or doctoral loan(s)" do
        it "is not valid without a value for 'postgraduate_doctoral_loan'" do
          expect(claim.has_masters_doctoral_loan?).to eql false
          expect(claim).not_to be_valid(:"doctoral-loan")
          expect(build(:claim, postgraduate_doctoral_loan: true)).to be_valid(:"doctoral-loan")
          expect(build(:claim, postgraduate_doctoral_loan: false)).to be_valid(:"doctoral-loan")
        end
      end

      context "with claim having no masters and/or doctoral loan(s)" do
        it "is valid without a value for 'postgraduate_doctoral_loan'" do
          subject.validate(on: :"doctoral-loan")
          expect(subject.errors[:"doctoral-loan"]).to be_empty
        end
      end
    end
  end

  context "when saving in the “email-address” validation context" do
    it "validates the presence of email_address" do
      expect(build(:claim)).not_to be_valid(:"email-address")
      expect(build(:claim, email_address: "name@example.tld")).to be_valid(:"email-address")
    end
  end

  context "with early-career payments policy" do
    subject(:claim) { build(:claim, policy: Policies::EarlyCareerPayments) }

    context "when saving in the “provide-mobile-number” validation context" do
      it "validates the presence of provide_mobile_number" do
        expect(claim).not_to be_valid(:"provide-mobile-number")
        expect(build(:claim, provide_mobile_number: true)).to be_valid(:"provide-mobile-number")
        expect(build(:claim, provide_mobile_number: false)).to be_valid(:"provide-mobile-number")
      end
    end

    context "with mobile number" do
      before do
        claim.provide_mobile_number = true
        claim.mobile_number = mobile_number
      end

      context "with UK number without spaces" do
        let(:mobile_number) { "07474000123" }
        it { is_expected.to be_valid(:mobile_number) }
      end

      context "with UK number with spaces" do
        let(:mobile_number) { "07474 000 123" }
        it { is_expected.to be_valid(:mobile_number) }
      end

      context "with international format number without spaces" do
        let(:mobile_number) { "+447474000123" }
        it { is_expected.to be_valid(:mobile_number) }
      end

      context "with international format number with spaces" do
        let(:mobile_number) { "+44 7474 000 123" }
        it { is_expected.to be_valid(:mobile_number) }
      end

      context "with international format non-UK number" do
        let(:mobile_number) { "+33 12 34 56 78" }
        it { is_expected.not_to be_valid(:mobile_number) }
      end
    end
  end

  context "when saving in the “personal-bank-account” validation context" do
    it "validates that the bank_account_number and bank_sort_code are present" do
      invalid_claim = build(:claim)
      valid_claim = build(:claim, bank_sort_code: "123456", bank_account_number: "87654321", banking_name: "Jo Bloggs")
      expect(invalid_claim).not_to be_valid(:"personal-bank-account")
      expect(valid_claim).to be_valid(:"personal-bank-account")
    end
  end

  context "when saving in the “building-society-account” validation context" do
    it "validates that the bank_account_number and bank_sort_code are present" do
      invalid_claim = build(:claim, bank_or_building_society: :building_society)
      valid_claim = build(
        :claim,
        bank_sort_code: "123456",
        bank_account_number: "87654321",
        banking_name: "Jo Bloggs",
        building_society_roll_number: "CXJ-K6 897/98X"
      )
      expect(invalid_claim).not_to be_valid(:"building-society-account")
      expect(valid_claim).to be_valid(:"building-society-account")
    end
  end

  context "when saving in the “submit” validation context" do
    it "validates the claim is in a submittable state" do
      expect(build(:claim)).not_to be_valid(:submit)
      expect(build(:claim, :submittable)).to be_valid(:submit)
    end

    it "validates the claim’s eligibility" do
      ineligible_claim = build(:claim, :submittable)
      ineligible_claim.eligibility.mostly_performed_leadership_duties = true

      expect(ineligible_claim).not_to be_valid(:submit)
      expect(ineligible_claim.errors.messages[:base]).to include("You’re not eligible for this payment")
    end
  end

  describe "#teacher_reference_number" do
    let(:claim) { build(:claim, teacher_reference_number: teacher_reference_number) }

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
      claim = create(:claim, national_insurance_number: "QQ 12 34 56 C")

      expect(claim.national_insurance_number).to eql("QQ123456C")
    end
  end

  describe "#student_loan_country" do
    it "captures the country the student loan was received in" do
      claim = build(:claim, student_loan_country: :england)
      expect(claim.student_loan_country).to eq("england")
    end

    it "rejects invalid countries" do
      expect { build(:claim, student_loan_country: :brazil) }.to raise_error(ArgumentError)
    end
  end

  describe "#student_loan_how_many_courses" do
    it "captures how many courses" do
      claim = build(:claim, student_loan_courses: :one_course)
      expect(claim.student_loan_courses).to eq("one_course")
    end

    it "rejects invalid responses" do
      expect { build(:claim, student_loan_courses: :one_hundred_courses) }.to raise_error(ArgumentError)
    end
  end

  describe "#no_student_loan?" do
    it "returns true if the claim has no student loan" do
      expect(build(:claim, has_student_loan: false).no_student_loan?).to eq true
      expect(build(:claim, has_student_loan: true).no_student_loan?).to eq false
    end
  end

  describe "#no_masters_doctoral_loan?" do
    it "returns true if the claim has no postgraduate masters and/or doctoral loan(s)" do
      expect(build(:claim, has_masters_doctoral_loan: false).no_masters_doctoral_loan?).to eq true
      expect(build(:claim, has_masters_doctoral_loan: true).no_masters_doctoral_loan?).to eq false
    end
  end

  describe "#student_loan_country_with_one_plan?" do
    it "returns true when the student_loan_country is one with only a single student loan plan" do
      expect(build(:claim).student_loan_country_with_one_plan?).to eq false

      StudentLoan::PLAN_1_COUNTRIES.each do |country|
        expect(build(:claim, student_loan_country: country).student_loan_country_with_one_plan?).to eq true
      end
    end
  end

  describe "#policy" do
    it "returns the claim’s policy namespace" do
      expect(Claim.new(eligibility: StudentLoans::Eligibility.new).policy).to eq StudentLoans
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.policy).to be_nil
    end
  end

  describe "#school" do
    let(:school) { build(:school) }

    it "returns the current_school of the claim eligiblity" do
      claim = Claim.new(eligibility: StudentLoans::Eligibility.new(current_school: school))
      expect(claim.school).to eq school
    end

    it "returns nil if no eligibility is set" do
      expect(Claim.new.school).to be_nil
    end
  end

  describe "#submit!" do
    around do |example|
      freeze_time { example.run }
    end

    context "when the claim is submittable" do
      let(:claim) { build(:claim, :submittable, policy: LevellingUpPremiumPayments, eligibility: eligibility) }
      let(:eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      before do
        create(:policy_configuration, :additional_payments)
        claim.submit!
      end

      it "sets submitted_at to now" do
        expect(claim.submitted_at).to eq Time.zone.now
      end

      it "generates a reference" do
        expect(claim.reference).to_not eq nil
      end

      it "sets the eligibility award amount" do
        expect(claim.eligibility.attributes["award_amount"]).to be_a(BigDecimal).and be_positive
      end
    end

    context "when a Reference clash with an existing claim occurs" do
      let(:claim) { create(:claim, :submittable) }

      before do
        other_claim = create(:claim, :submittable, reference: "12345678")
        expect(Reference).to receive(:new).once.and_return(double(to_s: other_claim.reference), double(to_s: "87654321"))
        claim.submit!
      end

      it "generates a unique reference" do
        expect(claim.reference).to eq("87654321")
      end
    end

    context "when the claim is ineligible" do
      let(:claim) { create(:claim, :ineligible) }

      it "raises an exception and adds an error" do
        expect { claim.submit! }
          .to raise_error(Claim::NotSubmittable)
          .and not_change { claim.reference }
          .and not_change { claim.submitted_at }
        expect(claim.errors.messages[:base]).to include("You’re not eligible for this payment")
      end
    end

    context "when the claim has already been submitted" do
      let(:claim) { create(:claim, :submitted, submitted_at: 2.days.ago) }

      it "raises an exception" do
        expect { claim.submit! }
          .to raise_error(Claim::NotSubmittable)
          .and not_change { claim.reference }
          .and not_change { claim.submitted_at }
      end
    end
  end

  describe "scopes" do
    let!(:submitted_claims) { create_list(:claim, 5, :submitted) }
    let!(:unsubmitted_claims) { create_list(:claim, 2, :submittable) }
    let!(:approved_claims) { create_list(:claim, 5, :approved) }
    let!(:rejected_claims) { create_list(:claim, 5, :rejected) }

    let!(:approved_then_rejected_claim) { create(:claim, :submitted) }
    let!(:rejected_then_approved_claim) { create(:claim, :submitted) }
    let!(:approved_then_decision_undone_claim) { create(:claim, :submitted) }
    let!(:rejected_then_decision_undone_claim) { create(:claim, :submitted) }

    # This doesn't feel great, but works - is this the best way?
    before do
      create(:decision, :approved, :undone, claim: approved_then_rejected_claim)
      create(:decision, :rejected, claim: approved_then_rejected_claim)

      create(:decision, :rejected, :undone, claim: rejected_then_approved_claim)
      create(:decision, :approved, claim: rejected_then_approved_claim)

      create(:decision, :approved, :undone, claim: approved_then_decision_undone_claim)

      create(:decision, :rejected, :undone, claim: rejected_then_decision_undone_claim)
    end

    describe "awaiting_decision" do
      it "returns submitted claims awaiting a decision" do
        expect(Claim.awaiting_decision).to match_array(submitted_claims + [approved_then_decision_undone_claim] + [rejected_then_decision_undone_claim])
      end
    end

    describe "approved" do
      it "returns approved claims" do
        expect(Claim.approved).to match_array(approved_claims + [rejected_then_approved_claim])
      end
    end

    describe "rejected" do
      it "returns rejected claims" do
        expect(Claim.rejected).to match_array(rejected_claims + [approved_then_rejected_claim])
      end
    end
  end

  describe ".awaiting_task" do
    let!(:claim_with_employment_task) { create(:claim, :submitted, tasks: [build(:task, name: "employment")]) }
    let!(:claim_with_qualification_task) { create(:claim, :submitted, tasks: [build(:task, name: "qualifications")]) }
    let!(:claim_with_no_tasks) { create(:claim, :submitted, tasks: []) }
    let!(:claim_with_decision) { create(:claim, :approved, tasks: [build(:task, name: "employment")]) }

    it "returns claims without a decision and without a given task" do
      expect(Claim.awaiting_task("qualifications")).to match_array([claim_with_employment_task, claim_with_no_tasks])
      expect(Claim.awaiting_task("employment")).to match_array([claim_with_qualification_task, claim_with_no_tasks])
    end
  end

  describe "by_academic_year" do
    let(:academic_year_2019) { AcademicYear.new("2019") }
    let(:academic_year_2020) { AcademicYear.new("2020") }

    let!(:academic_year_2019_claims) { create_list(:claim, 5, academic_year: academic_year_2019) }
    let!(:academic_year_2020_claims) { create_list(:claim, 5, academic_year: academic_year_2020) }

    it "returns claims for a specific academic year" do
      expect(Claim.by_academic_year(academic_year_2019.dup)).to match_array(academic_year_2019_claims)
      expect(Claim.by_academic_year(academic_year_2020.dup)).to match_array(academic_year_2020_claims)
    end
  end

  describe "#submittable?" do
    context "with student loans policy eligibility" do
      let(:policy) { StudentLoans }

      context "when submittable" do
        subject(:claim) { build(:claim, :submittable, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when submitted" do
        subject(:claim) { build(:claim, :submitted, policy:) }

        it { is_expected.not_to be_submittable }
      end
    end

    context "with early-career payments policy eligibility" do
      let(:policy) { Policies::EarlyCareerPayments }

      context "when submittable" do
        subject(:claim) { build(:claim, :submittable, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when using the mobile number from Teacher ID" do
        subject(:claim) { build(:claim, :submittable, using_mobile_number_from_tid: true, policy:) }

        it { is_expected.to be_submittable }
      end

      context "when submitted" do
        subject(:claim) { build(:claim, :submitted, policy:) }

        it { is_expected.not_to be_submittable }
      end
    end
  end

  describe "#approvable?" do
    it "returns true for a submitted claim with all required data present" do
      expect(build(:claim, :submitted).approvable?).to eq true
    end

    it "returns false for an unsubmitted claim" do
      expect(build(:claim, :submittable).approvable?).to eq false
    end

    it "returns false for a submitted claim that is missing a binary value for payroll_gender" do
      expect(build(:claim, :submitted, payroll_gender: :dont_know).approvable?).to eq false
    end

    it "returns true for a claim that already does not have a decision" do
      expect(build(:claim, :submitted).approvable?).to eq true
    end

    it "returns false when a claim has already been approved" do
      claim_with_decision = create(:claim, :submitted)
      expect(claim_with_decision.approvable?).to eq true
      create(:decision, claim: claim_with_decision, result: :approved)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false when a claim has already been rejected" do
      claim_with_decision = create(:claim, :submitted)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns true for a claim that has already been approved and awaiting QA" do
      claim_with_decision = create(:claim, :submitted, :flagged_for_qa)
      create(:decision, :approved, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq true
    end

    it "returns true for a claim that has already been rejected and awaiting QA" do
      claim_with_decision = create(:claim, :submitted, :flagged_for_qa)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq true
    end

    it "returns false for a claim that has already been approved and QA'd" do
      claim_with_decision = create(:claim, :submitted, :qa_completed)
      create(:decision, :approved, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false for a claim that has already been rejected and QA'd" do
      claim_with_decision = create(:claim, :submitted, :qa_completed)
      create(:decision, :rejected, claim: claim_with_decision)

      expect(claim_with_decision.approvable?).to eq false
    end

    it "returns false when there exists another payrollable claim with the same teacher reference number but with inconsistent attributes that would prevent us from running payroll" do
      teacher_reference_number = generate(:teacher_reference_number)
      create(:claim, :approved, teacher_reference_number: teacher_reference_number, date_of_birth: 20.years.ago)

      expect(create(:claim, :submitted, teacher_reference_number: teacher_reference_number, date_of_birth: 30.years.ago).approvable?).to eq false
    end

    context "when the claim is held" do
      subject(:claim) { create(:claim, :held) }
      it { is_expected.not_to be_approvable }
    end
  end

  describe "#rejectable?" do
    context "when the claim is held" do
      subject(:claim) { create(:claim, :held) }
      it { is_expected.not_to be_rejectable }
    end

    context "when the claim is not held" do
      subject(:claim) { create(:claim) }
      it { is_expected.to be_rejectable }
    end
  end

  describe "#flaggable_for_qa?" do
    subject { claim.flaggable_for_qa? }

    context "when a decision has not been made" do
      let(:claim) { create(:claim, :submitted) }

      it { is_expected.to eq(false) }
    end

    context "when the claim has been rejected" do
      let(:claim) { create(:claim, :rejected) }

      it { is_expected.to eq(false) }
    end

    context "when the claim has been approved" do
      let(:claim) { create(:claim, :approved) }

      context "when above the min QA threshold" do
        before do
          allow(Claim).to receive(:below_min_qa_threshold?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end

      context "when below the min QA threshold" do
        before do
          allow(Claim).to receive(:below_min_qa_threshold?).and_return(true)
        end

        it { is_expected.to eq(true) }
      end
    end

    context "when the claim has been flagged for QA already" do
      let(:claim) { create(:claim, :approved, :flagged_for_qa) }

      it { is_expected.to eq(false) }
    end

    context "when a QA decision has been made already" do
      let(:claim) { create(:claim, :approved, :qa_completed) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#qa_completed?" do
    subject { claim.qa_completed? }

    context "when the qa_completed_at is set" do
      let(:claim) { build_stubbed(:claim, :qa_completed) }

      it { is_expected.to eq(true) }
    end

    context "when the qa_completed_at is not set" do
      let(:claim) { build_stubbed(:claim, :flagged_for_qa) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#awaiting_qa?" do
    subject { claim.awaiting_qa? }

    context "when the qa_required is false" do
      let(:claim) { build_stubbed(:claim, qa_required: false) }

      it { is_expected.to eq(false) }
    end

    context "when the qa_required is true" do
      context "when the qa_completed_at is not set" do
        let(:claim) { build_stubbed(:claim, qa_required: true, qa_completed_at: nil) }

        it { is_expected.to eq(true) }
      end

      context "when the qa_completed_at is set" do
        let(:claim) { build_stubbed(:claim, qa_required: true, qa_completed_at: Time.zone.now) }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe "#decision" do
    it "returns the latest decision on a claim" do
      claim = create(:claim, :submitted)
      create(:decision, result: "approved", claim: claim, created_at: 7.days.ago)
      create(:decision, :rejected, claim: claim, created_at: DateTime.now)

      expect(claim.latest_decision.result).to eq "rejected"
    end

    it "returns only decisions which haven't been undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, :rejected, claim: claim)

      expect(claim.latest_decision).to be_nil
    end
  end

  describe "#payroll_gender_missing?" do
    it "returns true when the claimant doesn't know their payroll gender" do
      claim = build(:claim, payroll_gender: :dont_know)

      expect(claim.payroll_gender_missing?).to eq true
    end

    it "returns false when the payroll gender is one accepted by the payroll provider" do
      claim = build(:claim, payroll_gender: :female)

      expect(claim.payroll_gender_missing?).to eq false
    end
  end

  describe "#identity_verified?" do
    it "returns true if the claim has any GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).identity_verified?).to eq true
    end

    it "returns false if the claim doesn't have any GOV.UK Verify fields" do
      expect(Claim.new.identity_verified?).to eq false
      expect(Claim.new(govuk_verify_fields: []).identity_verified?).to eq false
    end
  end

  describe "#name_verified?" do
    it "returns true if the name is present in the list of GOV.UK Verify fields" do
      expect(Claim.new.name_verified?).to eq false
      expect(Claim.new(govuk_verify_fields: ["first_name"]).name_verified?).to eq true
    end
  end

  describe "#address_from_govuk_verify?" do
    it "returns true if any address attributes are in the list of GOV.UK Verify fields" do
      expect(Claim.new.address_from_govuk_verify?).to eq false
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).address_from_govuk_verify?).to eq false

      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).address_from_govuk_verify?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1", "postcode"]).address_from_govuk_verify?).to eq true
    end
  end

  describe "#date_of_birth_verified?" do
    it "returns true if date_of_birth is in the list of GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["date_of_birth"]).date_of_birth_verified?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).date_of_birth_verified?).to eq false
    end
  end

  describe "#payroll_gender_verified?" do
    it "returns true if payroll_gender is in the list of GOV.UK Verify fields" do
      expect(Claim.new(govuk_verify_fields: ["payroll_gender"]).payroll_gender_verified?).to eq true
      expect(Claim.new(govuk_verify_fields: ["address_line_1"]).payroll_gender_verified?).to eq false
    end
  end

  describe "#personal_data_removed?" do
    it "returns false if a claim has not had its personal data removed" do
      claim = create(:claim, :approved)
      expect(claim.personal_data_removed?).to eq false
    end

    it "returns true if a claim has the time personal data was removed recorded" do
      claim = create(:claim, :approved, personal_data_removed_at: Time.zone.now)
      expect(claim.personal_data_removed?).to eq true
    end
  end

  describe "#payrolled?" do
    it "returns false if a claim has not been added to payroll" do
      claim = create(:claim, :approved)
      expect(claim.payrolled?).to eq false
    end

    it "returns true if a claim has been added to payroll but is not yet paid" do
      claim = create(:claim, :approved)
      create(:payment, claims: [claim])
      expect(claim.payrolled?).to eq true
    end

    it "returns true if a claim has been scheduled for payment" do
      claim = create(:claim, :approved)
      create(:payment, :with_figures, claims: [claim])
      expect(claim.payrolled?).to eq true
    end
  end

  describe "#full_name" do
    it "joins the first name and surname together" do
      expect(Claim.new(first_name: "Isambard", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "joins the first name and surname together with only one space when middle name is an empty string" do
      expect(Claim.new(first_name: "Isambard", middle_name: "", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "joins the first name and surname together with only one space when middle name is a blank string" do
      expect(Claim.new(first_name: "Isambard", middle_name: " ", surname: "Brunel").full_name).to eq "Isambard Brunel"
    end

    it "includes a middle name when present" do
      expect(
        Claim.new(first_name: "Isambard", middle_name: "Kingdom", surname: "Brunel").full_name
      ).to eq "Isambard Kingdom Brunel"
    end
  end

  describe "#reset_dependent_answers" do
    let(:claim) { create(:claim, :submittable, :with_no_postgraduate_masters_doctoral_loan, bank_or_building_society: "building_society") }

    it "redetermines the student_loan_plan and resets loan plan answers when has_student_loan changes" do
      claim.has_student_loan = true
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.has_student_loan = false
      claim.reset_dependent_answers

      expect(claim.has_student_loan).to eq false
      expect(claim.student_loan_country).to be_nil
      expect(claim.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
      expect(claim.has_masters_doctoral_loan).to be_nil
      expect(claim.postgraduate_masters_loan).to be_nil
      expect(claim.postgraduate_doctoral_loan).to be_nil
    end

    it "redetermines the postgraduate masters and doctoral loans and resets subsequent two answers when has_student_loan changes" do
      claim.has_masters_doctoral_loan = nil
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.has_student_loan = false
      claim.reset_dependent_answers

      expect(claim.postgraduate_masters_loan).to be_nil
      expect(claim.postgraduate_doctoral_loan).to be_nil
    end

    it "redetermines the student_loan_plan and resets subsequent loan plan answers when student_loan_country changes" do
      claim.student_loan_country = :england
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_country = :scotland
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "scotland"
      expect(claim.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq StudentLoan::PLAN_4
    end

    it "redetermines the student_loan_plan and resets subsequent loan plan answers when student_loan_courses changes" do
      claim.student_loan_courses = :one_course
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_courses = :two_or_more_courses
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "england"
      expect(claim.student_loan_courses).to eq "two_or_more_courses"
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to be_nil
    end

    it "redetermines the student_loan_plan when the value of student_loan_start_date changes" do
      claim.student_loan_start_date = StudentLoan::BEFORE_1_SEPT_2012
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.student_loan_start_date = StudentLoan::ON_OR_AFTER_1_SEPT_2012
      claim.reset_dependent_answers
      expect(claim.has_student_loan).to eq true
      expect(claim.student_loan_country).to eq "england"
      expect(claim.student_loan_courses).to eq "one_course"
      expect(claim.student_loan_start_date).to eq StudentLoan::ON_OR_AFTER_1_SEPT_2012
      expect(claim.student_loan_plan).to eq StudentLoan::PLAN_2
    end

    it "redetermines the bank_details when the value of bank_or_building_society changes" do
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.bank_or_building_society = "personal_bank_account"
      claim.banking_name = "Mr David McCorkindale-Travers"
      claim.bank_sort_code = "984530"
      claim.bank_account_number = "66320109"

      expect(claim.banking_name).to eq "Mr David McCorkindale-Travers"
      expect(claim.bank_account_number).to eq "66320109"
      expect(claim.bank_sort_code).to eq "984530"
      expect(claim.building_society_roll_number).to be_nil
    end

    it "resets mobile_number when the value of provide_mobile_number changes" do
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.provide_mobile_number = false
      claim.reset_dependent_answers

      expect(claim.provide_mobile_number).to eq false
      expect(claim.mobile_number).to be_nil
    end

    it "resets mobile_verified when the value of mobile_number changes" do
      expect { claim.reset_dependent_answers }.not_to change { claim.attributes }

      claim.mobile_number = "07425999124"
      claim.reset_dependent_answers

      expect(claim.mobile_number).to eq "07425999124"
      expect(claim.mobile_verified).to be_nil
    end
  end

  describe ".filtered_params" do
    it "returns a list of sensitive params to be filtered" do
      expect(Claim.filtered_params).to match_array([
        :address_line_1,
        :address_line_2,
        :address_line_3,
        :address_line_4,
        :postcode,
        :payroll_gender,
        :teacher_reference_number,
        :national_insurance_number,
        :email_address,
        :mobile_number,
        :bank_sort_code,
        :bank_account_number,
        :date_of_birth,
        :date_of_birth_day,
        :date_of_birth_month,
        :date_of_birth_year,
        :first_name,
        :middle_name,
        :surname,
        :banking_name,
        :building_society_roll_number,
        :one_time_password,
        :assigned_to_id,
        :details_check,
        :email_address_check,
        :mobile_check,
        :qualifications_details_check
      ])
    end
  end

  describe ".below_min_qa_threshold?" do
    subject { described_class.below_min_qa_threshold? }

    context "when the MIN_QA_THRESHOLD is set to zero" do
      before do
        stub_const("Claim::MIN_QA_THRESHOLD", 0)
      end

      it { is_expected.to eq(false) }
    end

    context "when the MIN_QA_THRESHOLD is set to 10" do
      before do
        stub_const("Claim::MIN_QA_THRESHOLD", 10) unless described_class::MIN_QA_THRESHOLD == 10
      end

      context "with no previously approved claims" do
        it { is_expected.to eq(true) }
      end

      context "with 1 previously approved claim (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 1, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }

        it { is_expected.to eq(false) }
      end

      context "with 2 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 1, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }
        let!(:claims_not_flagged_for_qa) { create_list(:claim, 1, :approved, academic_year: AcademicYear.current) }

        it { is_expected.to eq(false) }
      end

      context "with 9 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 1, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }
        let!(:claims_not_flagged_for_qa) { create_list(:claim, 8, :approved, academic_year: AcademicYear.current) }

        it { is_expected.to eq(false) }
      end

      context "with 10 previously approved claims (1 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 1, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }
        let!(:claims_not_flagged_for_qa) { create_list(:claim, 9, :approved, academic_year: AcademicYear.current) }

        it { is_expected.to eq(true) }
      end

      context "with 11 previously approved claims (2 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 2, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }
        let!(:claims_not_flagged_for_qa) { create_list(:claim, 10, :approved, academic_year: AcademicYear.current) }

        it { is_expected.to eq(false) }
      end

      context "with 21 previously approved claims (2 flagged for QA)" do
        let!(:claims_flagged_for_qa) { create_list(:claim, 2, :approved, :flagged_for_qa, academic_year: AcademicYear.current) }
        let!(:claims_not_flagged_for_qa) { create_list(:claim, 19, :approved, academic_year: AcademicYear.current) }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe "::FILTER_PARAMS" do
    it "has a value for every claim attribute" do
      expect(Claim::FILTER_PARAMS.keys).to match_array(Claim.new.attribute_names.map(&:to_sym))
    end
  end

  describe ".payrollable" do
    subject { described_class.payrollable }

    let(:payroll_run) { create(:payroll_run, claims_counts: {StudentLoans => 1}) }
    let!(:submitted_claim) { create(:claim, :submitted) }
    let!(:first_unpayrolled_claim) { create(:claim, :approved) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved) }
    let(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    let!(:first_unpayrolled_claim) { create(:claim, :approved, submitted_at: 2.days.ago) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved, submitted_at: 1.day.ago) }

    it "returns approved claims not associated with a payroll run and ordered by submission date" do
      is_expected.to eq([first_unpayrolled_claim, second_unpayrolled_claim])
    end

    it "excludes claims that are awaiting QA" do
      claim_awaiting_qa
      claim_with_qa_completed

      is_expected.to eq([first_unpayrolled_claim, second_unpayrolled_claim, claim_with_qa_completed])
    end
  end

  describe ".not_awaiting_qa" do
    subject { described_class.not_awaiting_qa }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are approved and with QA completed" do
      is_expected.to match_array([claim_approved, claim_with_qa_completed])
    end
  end

  describe ".awaiting_qa" do
    subject { described_class.awaiting_qa }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are awaiting QA" do
      is_expected.to match_array([claim_awaiting_qa])
    end
  end

  describe ".qa_required" do
    subject { described_class.qa_required }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_awaiting_qa) { create(:claim, :approved, :flagged_for_qa) }
    let!(:claim_with_qa_completed) { create(:claim, :approved, :qa_completed) }

    it "returns approved claims that are flagged for QA" do
      is_expected.to match_array([claim_awaiting_qa, claim_with_qa_completed])
    end
  end

  describe ".auto_approved" do
    subject { described_class.auto_approved }

    let!(:claim_approved) { create(:claim, :approved) }
    let!(:claim_auto_approved) { create(:claim, :auto_approved) }
    let!(:another_claim_auto_approved) { create(:claim, :auto_approved) }

    it "returns claims that have been auto-approved" do
      is_expected.to match_array([claim_auto_approved, another_claim_auto_approved])
    end
  end

  describe "#amendable?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = build(:claim, :submittable)
      expect(claim.amendable?).to eq(false)
    end

    it "returns true for a submitted claim" do
      claim = build(:claim, :submitted)
      expect(claim.amendable?).to eq(true)
    end

    it "returns true for an approved claim" do
      claim = create(:claim, :approved)
      expect(claim.amendable?).to eq(true)
    end

    it "returns true for a rejected claim" do
      claim = create(:claim, :rejected)
      expect(claim.amendable?).to eq(true)
    end

    it "returns false for a payrolled claim" do
      claim = build(:claim, :approved)
      create(:payment, claims: [claim])

      expect(claim.amendable?).to eq(false)
    end

    it "returns false for a claim that’s had its personal data removed" do
      claim = build(:claim, :personal_data_removed)
      expect(claim.amendable?).to eq(false)
    end
  end

  describe "#decision_made?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = create(:claim, :submittable)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns false for a claim that has been submitted but not decided" do
      claim = create(:claim, :submitted)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns true for a claim that has been approved" do
      claim = create(:claim, :approved)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that has been rejected" do
      claim = create(:claim, :rejected)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that had a decison made, undone, then been approved" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, :rejected, claim: claim)
      create(:decision, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns true for a claim that had a decison made, undone, then been rejected" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      create(:decision, :rejected, claim: claim)
      expect(claim.decision_made?).to eq(true)
    end

    it "returns false for a claim that had a decison made, then undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(false)
    end
  end

  describe "#decision_undoable?" do
    it "returns false for a claim that hasn’t been submitted" do
      claim = create(:claim, :submittable)
      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns false for a submitted but undecided claim" do
      claim = create(:claim, :submitted)
      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns true for a rejected claim" do
      claim = create(:claim, :rejected)
      expect(claim.decision_undoable?).to eq(true)
    end

    it "returns false for a claim that had a decison made, then undone" do
      claim = create(:claim, :submitted)
      create(:decision, :undone, result: "approved", claim: claim)
      expect(claim.decision_made?).to eq(false)
    end

    it "returns true for an approved claim that isn’t payrolled" do
      claim = create(:claim, :approved)
      expect(claim.decision_undoable?).to eq(true)
    end

    it "returns false for a payrolled claim" do
      claim = create(:claim, :approved)
      create(:payment, claims: [claim])

      expect(claim.decision_undoable?).to eq(false)
    end

    it "returns false for a claim that’s had its personal data removed" do
      claim = create(:claim, :personal_data_removed)
      expect(claim.decision_undoable?).to eq(false)
    end
  end

  describe "#has_ecp_policy?" do
    let(:claim) { create(:claim, policy: policy) }

    context "with student loans policy" do
      let(:policy) { StudentLoans }

      it "returns false" do
        expect(claim.has_ecp_policy?).to eq(false)
      end
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns true" do
        expect(claim.has_ecp_policy?).to eq(true)
      end
    end
  end

  describe "#has_tslr_policy?" do
    let(:claim) { create(:claim, policy: policy) }

    context "with student loans policy" do
      let(:policy) { StudentLoans }

      it "returns true" do
        expect(claim.has_tslr_policy?).to eq(true)
      end
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it "returns false" do
        expect(claim.has_tslr_policy?).to eq(false)
      end
    end
  end

  describe "#has_lupp_policy?" do
    subject(:result) { claim.has_lupp_policy? }
    let(:claim) { create(:claim, policy: policy) }

    context "with student loans policy" do
      let(:policy) { StudentLoans }

      it { is_expected.to be false }
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to be false }
    end

    context "with levelling-up premium payments policy" do
      let(:policy) { LevellingUpPremiumPayments }

      it { is_expected.to be true }
    end
  end

  describe "#has_ecp_or_lupp_policy?" do
    subject(:result) { claim.has_ecp_or_lupp_policy? }
    let(:claim) { create(:claim, policy: policy) }

    context "with student loans policy" do
      let(:policy) { StudentLoans }

      it { is_expected.to be false }
    end

    context "with early-career payments policy" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to be true }
    end

    context "with levelling-up premium payments policy" do
      let(:policy) { LevellingUpPremiumPayments }

      it { is_expected.to be true }
    end
  end

  describe "#important_notes" do
    subject(:important_notes) do
      claim.important_notes
    end

    let(:claim) { create(:claim, notes: notes) }

    context "without important notes" do
      let(:notes) { create_list(:note, 2, important: false) }

      it { is_expected.to be_empty }
    end

    context "with important notes" do
      let(:notes) { create_list(:note, 2, important: true) }

      it { is_expected.to match_array notes }
    end
  end

  describe "#destroy" do
    let(:claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }

    before do
      create(:note, claim: claim)
      create(:task, claim: claim)
      create(:amendment, claim: claim)
      create(:decision, :approved, claim: claim)
      create(:support_ticket, claim: claim)
    end

    it "destroys associated records" do
      claim.reload.destroy!
      expect(EarlyCareerPayments::Eligibility.count).to be_zero
      expect(Note.count).to be_zero
      expect(Task.count).to be_zero
      expect(Amendment.count).to be_zero
      expect(Decision.count).to be_zero
      expect(SupportTicket.count).to be_zero
    end
  end

  describe "#hold!" do
    let(:reason) { "test" }
    let(:user) { build(:dfe_signin_user) }

    before { claim.hold!(reason: reason, user: user) }

    context "when the claim is already held" do
      subject(:claim) { build(:claim, :held) }

      it { is_expected.to be_held }

      it "does not add a note" do
        expect(claim.notes).to be_empty
      end
    end

    context "when the claim cannot be held" do
      subject(:claim) { build(:claim, :approved) }

      it { is_expected.not_to be_held }
    end

    context "when the claim is not already held" do
      subject(:claim) { build(:claim) }

      it { is_expected.to be_held }

      it "adds a note" do
        expect(claim.notes.first.body).to eq "Claim put on hold: #{reason}"
        expect(claim.notes.first.created_by).to eq user
      end
    end
  end

  describe "#unhold!" do
    let(:user) { build(:dfe_signin_user) }

    before { claim.unhold!(user: user) }

    context "when the claim is held" do
      subject(:claim) { build(:claim, :held) }

      it { is_expected.not_to be_held }

      it "adds a note" do
        expect(claim.notes.first.body).to eq "Claim hold removed"
        expect(claim.notes.first.created_by).to eq user
      end
    end

    context "when the claim is not held" do
      subject(:claim) { build(:claim) }

      it { is_expected.not_to be_held }

      it "does not add a note" do
        expect(claim.notes).to be_empty
      end
    end
  end

  describe "#holdable?" do
    context "when the claim has no approval decision" do
      subject(:claim) { build(:claim, :submitted) }
      it { is_expected.to be_holdable }
    end

    context "when the claim has is approved" do
      subject(:claim) { build(:claim, :rejected) }
      it { is_expected.not_to be_holdable }
    end

    context "when the claim has is rejected" do
      subject(:claim) { build(:claim, :rejected) }
      it { is_expected.not_to be_holdable }
    end
  end

  describe "#must_manually_validate_bank_details?" do
    context "when bank details have been validated" do
      subject(:claim) { build(:claim, :bank_details_validated) }
      it { is_expected.not_to be_must_manually_validate_bank_details }
    end

    context "when bank details have not been validated" do
      subject(:claim) { build(:claim, :bank_details_not_validated) }
      it { is_expected.to be_must_manually_validate_bank_details }
    end
  end

  describe "#recent_tps_school" do
    before { freeze_time }
    after { travel_back }

    let(:trn) { "7654321" }
    let(:establishment_number) { 1234 }

    let!(:claim) { create(:claim, teacher_reference_number: trn, created_at: Time.zone.now) }
    let!(:school) { create(:school, establishment_number:) }

    context "when there is a tps record within 2 full months" do
      it "returns a school" do
        # This is how it's stored in imported TPS records!
        start_date = (Time.zone.now - 2.months).beginning_of_month
        end_date = start_date.end_of_month.beginning_of_day

        create(:teachers_pensions_service, start_date: start_date, end_date: end_date, school_urn: establishment_number, la_urn: school.local_authority.code, teacher_reference_number: trn)

        expect(claim.recent_tps_school.establishment_number).to be(establishment_number)
      end
    end

    context "when the last tps record is earlier than 2 full months ago" do
      it "returns nil" do
        # This is how it's stored in imported TPS records!
        start_date = (Time.zone.now - 3.months).beginning_of_month
        end_date = start_date.end_of_month.beginning_of_day

        create(:teachers_pensions_service, start_date: start_date, end_date: end_date, school_urn: establishment_number, teacher_reference_number: trn)

        expect(claim.recent_tps_school).to be_nil
      end
    end
  end

  describe "#has_all_valid_personal_details?" do
    context "first_name, surname, dob and nino are the same as tid" do
      let(:claim) {
        create(
          :claim,
          :submitted,
          first_name: "John", surname: "Doe",
          date_of_birth: Date.new(1980, 1, 11),
          national_insurance_number: "JH001234D",
          teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => "JH001234D"}
        )
      }

      it "returns true" do
        expect(claim.has_all_valid_personal_details?).to be true
      end
    end

    context "nino is empty" do
      let(:claim) {
        create(
          :claim,
          :submitted,
          first_name: "John", surname: "Doe",
          date_of_birth: Date.new(1980, 1, 11),
          national_insurance_number: "JH001234D",
          teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => nil}
        )
      }

      it "returns false" do
        expect(claim.has_all_valid_personal_details?).to be false
      end
    end

    context "first_name and surname is invalid" do
      let(:claim) {
        create(
          :claim,
          :submitted,
          first_name: "J@hn", surname: "D@e",
          date_of_birth: Date.new(1980, 1, 11),
          national_insurance_number: "JH001234D",
          teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => "JH001234D"}
        )
      }

      it "returns false" do
        expect(claim.has_all_valid_personal_details?).to be false
      end
    end
  end

  describe "#has_valid_name?" do
    let(:claim) {
      create(
        :claim,
        :submitted,
        first_name: first_name, surname: surname,
        date_of_birth: Date.new(1980, 1, 11),
        national_insurance_number: "JH001234D",
        teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => "JH001234D"}
      )
    }

    context "valid" do
      let(:first_name) { "John" }
      let(:surname) { "Doe" }

      it "returns true" do
        expect(claim.has_valid_name?).to be true
      end
    end

    context "invalid first_name" do
      let(:first_name) { "J@hn" }
      let(:surname) { "Doe" }

      it "returns false" do
        expect(claim.has_valid_name?).to be false
      end
    end

    context "invalid surname" do
      let(:first_name) { "John" }
      let(:surname) { "D@e" }

      it "returns false" do
        expect(claim.has_valid_name?).to be false
      end
    end

    context "blank" do
      let(:first_name) { "" }
      let(:surname) { "" }

      it "returns false" do
        expect(claim.has_valid_name?).to be false
      end
    end
  end

  describe "#has_valid_date_of_birth?" do
    let(:claim) {
      create(
        :claim,
        :submitted,
        first_name: "John", surname: "Doe",
        date_of_birth: dob,
        national_insurance_number: "JH001234D",
        teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => "JH001234D"}
      )
    }

    context "valid" do
      let(:dob) { Date.new(1980, 1, 11) }

      it "returns true" do
        expect(claim.has_valid_date_of_birth?).to be true
      end
    end

    context "nil" do
      let(:dob) { nil }

      it "returns false" do
        expect(claim.has_valid_date_of_birth?).to be false
      end
    end
  end

  describe "#has_valid_nino?" do
    let(:claim) {
      create(
        :claim,
        :submitted,
        first_name: "John", surname: "Doe",
        date_of_birth: Date.new(1980, 1, 11),
        national_insurance_number: nino,
        teacher_id_user_info: {"given_name" => "John", "family_name" => "Doe", "birthdate" => "1980-01-11", "ni_number" => "JH001234D"}
      )
    }

    context "valid" do
      let(:nino) { "JH001234D" }

      it "returns true" do
        expect(claim.has_valid_nino?).to be true
      end
    end

    context "nil" do
      let(:nino) { nil }

      it "returns false" do
        expect(claim.has_valid_nino?).to be false
      end
    end
  end

  describe "#has_dqt_record?" do
    let(:claim) { build(:claim, dqt_teacher_status:) }
    subject(:result) { claim.has_dqt_record? }

    context "when dqt_teacher_status value is nil" do
      let(:dqt_teacher_status) { nil }
      it { is_expected.to be false }
    end

    context "when dqt_teacher_status value is empty" do
      let(:dqt_teacher_status) { {} }
      it { is_expected.to be false }
    end

    context "when dqt_teacher_status value is not empty" do
      let(:dqt_teacher_status) { {"test" => "test"} }
      it { is_expected.to be true }
    end
  end

  describe "#dqt_teacher_record" do
    let(:claim) { build(:claim, dqt_teacher_status:) }
    subject(:result) { claim.dqt_teacher_record }

    context "when dqt_teacher_status value is nil" do
      let(:dqt_teacher_status) { nil }
      it { is_expected.to be nil }
    end

    context "when dqt_teacher_status value is empty" do
      let(:dqt_teacher_status) { {} }
      it { is_expected.to be nil }
    end

    context "when dqt_teacher_status value is not empty" do
      let(:dqt_teacher_status) { {"test" => "test"} }
      it { is_expected.to be_a(claim.policy::DqtRecord) }
    end
  end
end
