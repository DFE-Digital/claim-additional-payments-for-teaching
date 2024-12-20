require "rails_helper"

RSpec.describe Claim::MatchingAttributeFinder do
  describe "#matching_claims" do
    let!(:source_claim) {
      create(:claim,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        building_society_roll_number: "123456789/ABCD",
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {teacher_reference_number: "0902344"})
    }

    let!(:student_loans_claim) {
      create(:claim,
        :submitted,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        building_society_roll_number: "123456789/ABCD",
        policy: Policies::StudentLoans,
        eligibility_attributes: {teacher_reference_number: "0902344"})
    }

    let!(:lup_claim) {
      create(:claim,
        :submitted,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        building_society_roll_number: "123456789/ABCD",
        policy: Policies::LevellingUpPremiumPayments,
        eligibility_attributes: {teacher_reference_number: "0902344"})
    }

    let!(:fe_claim) {
      create(:claim,
        :submitted,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        building_society_roll_number: "123456789/ABCD",
        policy: Policies::FurtherEducationPayments,
        eligibility_attributes: {teacher_reference_number: "0902344"})
    }

    let!(:ey_claim) {
      create(:claim,
        :submitted,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        policy: Policies::EarlyYearsPayments)
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it "includes claims for ECP, LUP, FE and EY claims" do
      expect(matching_claims).to contain_exactly(lup_claim, student_loans_claim, fe_claim, ey_claim)
    end
  end

  describe "#matching_claims" do
    let(:source_claim) {
      create(:claim,
        first_name: "Genghis",
        surname: "Khan",
        date_of_birth: Date.new(1162, 5, 31),
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        academic_year: AcademicYear.new("2019"),
        building_society_roll_number: "123456789/ABCD",
        policy: Policies::StudentLoans,
        eligibility_attributes: {teacher_reference_number: "0902344"})
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it "does not include the source claim" do
      expect(matching_claims).to be_empty
    end

    it "does not include claims that do not match" do
      create(:claim, :submitted)

      expect(matching_claims).to be_empty
    end

    it "does not include claims that match, but have a different policy" do
      student_loans_claim = create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: source_claim.eligibility.teacher_reference_number}, policy: Policies::StudentLoans)

      expect(matching_claims).to contain_exactly(student_loans_claim)
    end

    it "does not include claims that match, but have a different academic year" do
      create(:claim, :submitted,
        eligibility_attributes: {teacher_reference_number: source_claim.eligibility.teacher_reference_number},
        academic_year: AcademicYear.new("2020"),
        policy: source_claim.policy)

      expect(matching_claims).to be_empty
    end

    it "includes a claim with a matching teacher reference number" do
      claim_with_matching_attribute = create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: source_claim.eligibility.teacher_reference_number})

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching national insurance number" do
      claim_with_matching_attribute = create(:claim, :submitted, national_insurance_number: source_claim.national_insurance_number)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching national insurance number with a different capitalisation" do
      claim_with_matching_attribute = create(:claim, :submitted, national_insurance_number: source_claim.national_insurance_number.downcase)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching email address" do
      claim_with_matching_attribute = create(:claim, :submitted, email_address: source_claim.email_address)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching email address with a different capitalisation" do
      claim_with_matching_attribute = create(:claim, :submitted, email_address: source_claim.email_address.upcase)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "does not include a claim with a matching bank account number" do
      create(:claim, :submitted, bank_account_number: source_claim.bank_account_number)

      expect(matching_claims).to eq([])
    end

    it "does not include a claim with a matching bank sort code" do
      create(:claim, :submitted, bank_sort_code: source_claim.bank_sort_code)

      expect(matching_claims).to eq([])
    end

    it "does not include a claim with a matching building society roll number" do
      create(:claim, :submitted, building_society_roll_number: source_claim.building_society_roll_number)

      expect(matching_claims).to eq([])
    end

    it "includes a claim with a matching bank account number and sort code" do
      source_claim.update!(building_society_roll_number: nil)
      claim_with_matching_attributes = create(:claim, :submitted,
        bank_account_number: source_claim.bank_account_number,
        bank_sort_code: source_claim.bank_sort_code)

      expect(matching_claims).to eq([claim_with_matching_attributes])
    end

    it "includes a claim with a matching bank account number, sort code and roll number" do
      claim_with_matching_attributes = create(:claim, :submitted,
        bank_account_number: source_claim.bank_account_number,
        bank_sort_code: source_claim.bank_sort_code,
        building_society_roll_number: source_claim.building_society_roll_number)

      expect(matching_claims).to eq([claim_with_matching_attributes])
    end

    it "does not match claims with nil building society roll numbers" do
      source_claim.update!(building_society_roll_number: nil)
      create(:claim, :submitted, building_society_roll_number: nil)

      expect(matching_claims).to be_empty
    end

    it "does not match claims with blank building society roll numbers" do
      source_claim.update!(building_society_roll_number: "")
      create(:claim, :submitted, building_society_roll_number: "")

      expect(matching_claims).to be_empty
    end

    it "does not include a claim with a matching name" do
      create(
        :claim,
        :submitted,
        first_name: source_claim.first_name,
        surname: source_claim.surname
      )

      expect(matching_claims).to be_empty
    end

    it "does not include a claim with a matching date of birth" do
      create(
        :claim,
        :submitted,
        date_of_birth: source_claim.date_of_birth
      )

      expect(matching_claims).to be_empty
    end

    it "includes a claim with a matching name and date of birth" do
      claim_with_matching_attributes = create(
        :claim,
        :submitted,
        first_name: source_claim.first_name,
        surname: source_claim.surname,
        date_of_birth: source_claim.date_of_birth
      )

      expect(matching_claims).to eq([claim_with_matching_attributes])
    end

    context "when the policy has an array of attributes in ELIGIBILITY_MATCHING_ATTRIBUTES" do # current policies don't do this
      before do
        allow(Policies::StudentLoans).to receive(:eligibility_matching_attributes) { [["teacher_reference_number", "current_school_id"]] }
      end

      it "does not include a claim that only partially matches eligibility_matching_attributes" do
        create(
          :claim,
          :submitted,
          eligibility_attributes: {teacher_reference_number: "0902344"}
        )

        expect(matching_claims).to be_empty
      end

      context "when matching with a claim that has one but not all of the eligibility_matching_attributes" do
        it "does not include" do
          create(
            :claim,
            :submitted,
            policy: Policies::FurtherEducationPayments,
            eligibility_attributes: {teacher_reference_number: "0902344"}
          )

          expect(matching_claims).to be_empty
        end
      end
    end
  end

  describe "matching_claims - blank trn" do
    let(:policy) { Policies::FurtherEducationPayments }

    let!(:source_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility
      )
    }

    let!(:other_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility,
        surname: Faker::Name.last_name
      )
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it { is_expected.to be_empty }
  end

  describe "matching_claims - same trn" do
    let(:policy) { Policies::FurtherEducationPayments }

    let!(:source_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible, :with_trn)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility
      )
    }

    let!(:other_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible, teacher_reference_number: source_claim.eligibility.teacher_reference_number)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility,
        surname: Faker::Name.last_name
      )
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it { is_expected.to eq [other_claim] }
  end

  describe "matching_claims - blank trn, matching email addresses" do
    let(:policy) { Policies::FurtherEducationPayments }

    let!(:source_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility,
        email_address: "match@example.com"
      )
    }

    let!(:other_claim) {
      eligibility = create(:further_education_payments_eligibility, :eligible)
      create(
        :claim,
        :submitted,
        policy: policy,
        eligibility: eligibility,
        surname: Faker::Name.last_name,
        email_address: "match@example.com"
      )
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it { is_expected.to eq [other_claim] }
  end

  describe "#matching_attributes" do
    it "returns the attributes that match" do
      source_claim = create(
        :claim,
        first_name: "genghis",
        surname: "khan",
        email_address: "genghis.khan@example.com",
        national_insurance_number: "QQ891011C",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        eligibility_attributes: {
          teacher_reference_number: "0902344"
        }
      )

      other_claim = create(
        :claim,
        first_name: "genghis",
        surname: "khan2",
        email_address: "genghis.khan@example.com",
        national_insurance_number: "QQ891011C",
        bank_account_number: "11111111",
        bank_sort_code: "972654",
        eligibility_attributes: {
          teacher_reference_number: "0902344"
        }
      )

      expect(
        described_class.new(source_claim).matching_attributes(other_claim)
      ).to eq(
        %w[email_address national_insurance_number teacher_reference_number]
      )
    end
  end
end
