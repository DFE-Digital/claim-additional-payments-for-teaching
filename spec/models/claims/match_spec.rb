require "rails_helper"

RSpec.describe Claims::Match do
  describe ".update_matching_claims!" do
    it "creates matches for any new claims" do
      new_claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111111",
        bank_sort_code: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago,
        eligibility_attributes: {
          teacher_reference_number: "0000000"
        }
      )

      matching_claim_1 = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111112C",
        bank_account_number: "11111112",
        bank_sort_code: "111112",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 2),
        academic_year: AcademicYear.current,
        created_at: 2.days.ago
      )

      matching_claim_2 = create(
        :claim,
        email_address: "e.krabapple@gmail.com",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111113",
        bank_sort_code: "111113",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 2),
        academic_year: AcademicYear.current,
        created_at: 2.days.ago
      )

      matching_claim_3 = create(
        :claim,
        email_address: "e.krabapple@example.com",
        national_insurance_number: "AB111111D",
        bank_account_number: "11111112",
        bank_sort_code: "111112",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 2.days.ago
      )

      described_class.update_matching_claims!(new_claim)

      matches = described_class.matches(new_claim)

      match_1 = matches.find_by!(left_claim: matching_claim_1)

      expect(match_1.other(new_claim)).to eq(matching_claim_1)

      expect(match_1.matching_attributes).to match_array(["email_address"])

      match_2 = matches.find_by!(left_claim: matching_claim_2)

      expect(match_2.other(new_claim)).to eq(matching_claim_2)

      expect(match_2.matching_attributes).to match_array([
        "national_insurance_number"
      ])

      match_3 = matches.find_by!(left_claim: matching_claim_3)

      expect(match_3.other(new_claim)).to eq(matching_claim_3)

      expect(match_3.matching_attributes).to match_array([
        "first_name",
        "surname",
        "date_of_birth"
      ])

      expect(described_class.matching_claims(new_claim)).to match_array([
        matching_claim_1,
        matching_claim_2,
        matching_claim_3
      ])
    end

    it "removes matches for claims that are no longer matching" do
      claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111111",
        bank_sort_code: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago,
        eligibility_attributes: {
          teacher_reference_number: "0000000"
        }
      )

      existing_matching_claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111112C",
        bank_account_number: "11111112",
        bank_sort_code: "111112",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 2),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago
      )

      match = described_class.create_match!(claim, existing_matching_claim)

      expect(match.matching_attributes).to match_array(["email_address"])

      expect(described_class.matches(claim)).to eq([match])

      claim.update!(email_address: "edna.krabapple@springfield-elementary.edu")

      described_class.update_matching_claims!(claim)

      matches = described_class.matches(claim)

      expect(matches).to be_empty
    end

    it "can recreate a match that was previously removed" do
      claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111111",
        bank_sort_code: "111111",
        building_society_roll_number: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago,
        eligibility_attributes: {
          teacher_reference_number: "0000000"
        }
      )

      existing_matching_claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111112C",
        bank_account_number: "11111112",
        bank_sort_code: "111112",
        building_society_roll_number: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 2),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago
      )

      described_class.create_match!(claim, existing_matching_claim)

      claim.update!(email_address: "edna.krabapple@springfield-elementary.edu")

      described_class.update_matching_claims!(claim)

      expect(described_class.matches(claim)).to be_empty

      claim.update!(
        email_address: "e.krabapple@springfield-elementary.edu",
        bank_account_number: "11111112",
        bank_sort_code: "111112"
      )

      match = described_class.create_match!(claim, existing_matching_claim)

      expect(described_class.matching_claims(claim)).to eq([
        existing_matching_claim
      ])

      expect(match.matching_attributes).to match_array([
        "email_address",
        "bank_account_number",
        "bank_sort_code",
        "building_society_roll_number"
      ])
    end

    it "updates existing matches to reflect any changes in matching attributes" do
      claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111111",
        bank_sort_code: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago,
        eligibility_attributes: {
          teacher_reference_number: "0000000"
        }
      )

      existing_matching_claim = create(
        :claim,
        email_address: "e.krabapple@springfield-elementary.edu",
        national_insurance_number: "AB111111C",
        bank_account_number: "11111111",
        bank_sort_code: "111111",
        first_name: "Edna",
        surname: "Krabapple",
        date_of_birth: Date.new(1970, 1, 1),
        academic_year: AcademicYear.current,
        created_at: 1.day.ago
      )

      match = described_class.create_match!(claim, existing_matching_claim)

      expect(match.matching_attributes).to match_array([
        "email_address",
        "national_insurance_number",
        "bank_account_number",
        "bank_sort_code",
        "building_society_roll_number",
        "first_name",
        "surname",
        "date_of_birth"
      ])

      claim.update!(
        email_address: "edna.krabapple@springfield-elementary.edu",
        date_of_birth: Date.new(1970, 1, 2)
      )

      described_class.update_matching_claims!(claim)

      matches = described_class.matches(claim)

      match = matches.first

      expect(match.matching_attributes).to match_array([
        "national_insurance_number",
        "bank_account_number",
        "bank_sort_code",
        "building_society_roll_number"
      ])
    end
  end
end
