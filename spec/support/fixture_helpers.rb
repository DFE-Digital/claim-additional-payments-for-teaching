module FixtureHelpers
  # Helper to be used in specs in conjunction with `example_dqt_report.csv`,
  # The claims defined here are associated with the rows in the CSV.
  #
  # Examples
  #
  #   claim_from_example_dqt_report(:eligible_claim_with_matching_data)
  #   # => Claim
  def claim_from_example_dqt_report(trait)
    case trait
    when :eligible_claim_with_matching_data
      # Eligible claim with matching name and DOB in DQT
      create(:claim, :submitted,
        first_name: "FRED",
        surname: "ELIGIBLE",
        eligibility_attributes: {teacher_reference_number: "1234567"},
        reference: "AB123456",
        date_of_birth: Date.new(1990, 8, 23),
        national_insurance_number: "QQ123456C")

    when :eligible_claim_with_matching_data_and_hecos_code
      # Eligible claim with matching, name, DOB and HECOS code in DQT
      create(:claim, :submitted,
        first_name: "Dwayne",
        surname: "Hecos",
        eligibility_attributes: {teacher_reference_number: "9876543"},
        reference: "ZY987654",
        date_of_birth: Date.new(1991, 1, 8),
        national_insurance_number: "QQ123456C")

    when :eligible_claim_with_non_matching_birthdate
      # Eligible claim and eligible DQT data but different date of birth
      create(:claim, :submitted,
        first_name: "Jo",
        surname: "Eligible",
        eligibility_attributes: {teacher_reference_number: "8901231"},
        reference: "RR123456",
        date_of_birth: Date.new(1899, 1, 1),
        national_insurance_number: "QQ123456C")

    when :eligible_claim_with_non_matching_surname
      # Eligible claim and eligible DQT data but different surname
      create(:claim, :submitted,
        first_name: "Sarah",
        surname: "Eligible",
        eligibility_attributes: {teacher_reference_number: "8981212"},
        reference: "DD123456",
        date_of_birth: Date.new(1980, 4, 10),
        national_insurance_number: "QQ123456C")

    when :claim_without_dqt_record
      # Submitted claim that has no DQT associated with it
      create(:claim, :submitted, eligibility_attributes: {teacher_reference_number: "3456789"}, reference: "XX123456")

    when :claim_with_ineligible_dqt_record
      # Submitted claim with matching data in DQT that is considered ineligible
      create(:claim, :submitted,
        eligibility_attributes: {teacher_reference_number: "6758493"},
        reference: "CD123456",
        date_of_birth: Date.new(1979, 4, 21))

    when :claim_with_decision
      # Eligible claim with matching data that already has a decision
      create(:claim, :approved,
        eligibility_attributes: {teacher_reference_number: "5554433"},
        reference: "EF123456",
        date_of_birth: Date.new(1985, 5, 15))

    when :claim_with_qualification_task
      # Eligible claim with matching data that already has a qualification task
      create(:claim, :submitted,
        eligibility_attributes: {teacher_reference_number: "6060606"},
        reference: "GH123456",
        date_of_birth: Date.new(1980, 10, 4),
        tasks: [build(:task, name: "qualifications")])
    end
  end

  # Returns the example DQT report that is used in conjunction with the claim
  # factory helper above.
  def example_dqt_report_csv
    File.open("spec/fixtures/files/example_dqt_report.csv")
  end
end
