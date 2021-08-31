# Run me with `rails runner db/data/20210827115900_update_ecp_claims_with_academic_year_2020_to_2021.rb`
puts "One off Private Beta (prior to 1st Sept 2021) data migration to fix ECP-1158"
puts <<~BACKGROUND
  Part One of Two
    - Fixing Early Career Payment Claims.academic_year
    - criteria:
      - policy: EarlyCareerPayments
      - academic_year: 2020/2021
    - update:
      - academic_year: AcademicYear.new(2021)
BACKGROUND
cecp = Claim.by_policy(EarlyCareerPayments).where(academic_year: "2020/2021")
puts "No. records: #{cecp.size}"

cecp.update_all(academic_year: AcademicYear.new(2021))
cecp_2020_after = Claim.by_policy(EarlyCareerPayments).where(academic_year: "2020/2021")
cecp_2021_after = Claim.by_policy(EarlyCareerPayments).where(academic_year: "2021/2022")

puts <<~AFTER
  No. records
    - academic_year (2020): #{cecp_2020_after.size}
    - academic_year (2021): #{cecp_2021_after.size}
AFTER

puts <<~PART_TWO_BACKGOUND
  Part Two of Two
    - Fixing PolicyConfiguration
    - criteria:
      - policy: EarlyCareerPayments
    - update:
      - current_academic_year: AcademicYear.new(2021)
PART_TWO_BACKGOUND

pc_for_ecp = PolicyConfiguration.find_by(policy_type: "EarlyCareerPayments")
pc_for_ecp.current_academic_year = AcademicYear.new(2021)
pc_for_ecp.save

pc_ecp_current_academic_year = PolicyConfiguration.find_by(policy_type: "EarlyCareerPayments").current_academic_year

if cecp_2020_after.size == 0 && pc_ecp_current_academic_year == "2021/2022"
  puts "     ***  Migration finished ***"
else
  puts <<~WARNING
    There might still be breakages in admin site
    when clicking 'Check qualification information' link
    Additional investigation might be required
  WARNING
end
