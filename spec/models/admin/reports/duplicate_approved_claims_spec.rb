require "rails_helper"

RSpec.describe Admin::Reports::DuplicateApprovedClaims do
  describe "#to_csv" do
    it "includes claims with duplicate details, excludes claims that aren't duplicates" do
      claim_1 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        email_address: "duplicate@example.com",
        reference: "claim 1"
      )

      claim_2 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        email_address: "duplicate@example.com",
        reference: "claim 2"
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        email_address: "non-duplicate@example.com",
        reference: "nondupe1"
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        national_insurance_number: "AB123456D",
        reference: "nondupe2"
      )

      claim_3 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        reference: "claim 3"
      )

      claim_4 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        reference: "claim 4"
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        bank_account_number: "12345679",
        bank_sort_code: "123456",
        reference: "nondupe3"
      )

      claim_5 = create(
        :claim,
        :approved,
        :current_academic_year,
        first_name: "SEYMOUR",
        surname: "Skinner",
        date_of_birth: Date.new(1960, 1, 1),
        reference: "claim 5"
      )

      claim_6 = create(
        :claim,
        :approved,
        :current_academic_year,
        first_name: "Seymour",
        surname: "Skinner",
        date_of_birth: Date.new(1960, 1, 1),
        reference: "claim 6"
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        first_name: "Seymour",
        surname: "Skinner",
        date_of_birth: Date.new(1960, 1, 2),
        reference: "nondupe4"
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      claim_references = csv.map { |row| row["Claim reference"] }

      expect(claim_references).to match_array([
        claim_1.reference,
        claim_2.reference,
        claim_3.reference,
        claim_4.reference,
        claim_5.reference,
        claim_6.reference
      ])
    end

    it "includes claims with duplicate eligibility details" do
      claim_1 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        reference: "claim 1",
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      claim_2 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        reference: "claim 2",
        policy: Policies::LevellingUpPremiumPayments,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      claim_3 = create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        reference: "claim 3",
        policy: Policies::FurtherEducationPayments,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        reference: "nondupe1",
        policy: Policies::InternationalRelocationPayments
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        :random_name,
        reference: "nondupe2",
        policy: Policies::StudentLoans,
        eligibility_attributes: {
          teacher_reference_number: "1234568"
        }
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      claim_references = csv.map { |row| row["Claim reference"] }

      expect(claim_references).to match_array([
        claim_1.reference,
        claim_2.reference,
        claim_3.reference
      ])
    end

    it "excludes claims with duplicate details that are not approved" do
      create(
        :claim,
        :approved,
        :current_academic_year,
        email_address: "duplicate@example.com",
        reference: "claim 1"
      )

      create(
        :claim,
        :current_academic_year,
        email_address: "duplicate@example.com",
        reference: "claim 2"
      )

      create(
        :claim,
        :approved,
        :random_name,
        :current_academic_year,
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        },
        reference: "claim 3"
      )

      create(
        :claim,
        :random_name,
        :current_academic_year,
        policy: Policies::EarlyCareerPayments,
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        },
        reference: "claim 4"
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      expect(csv.count).to eq(0)
    end

    it "excludes claims with duplicate details across academic years" do
      create(
        :claim,
        :approved,
        email_address: "duplicate@example.com",
        academic_year: AcademicYear.new(2021)
      )

      create(
        :claim,
        :approved,
        :current_academic_year,
        email_address: "duplicate@example.com"
      )

      csv = CSV.parse(described_class.new.to_csv, headers: true)

      expect(csv.count).to eq(0)
    end
  end
end
