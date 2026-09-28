# generates 3 csvs
# for the specified academic year
# file 1 contains list of FE providers with claim counts
# file 2 contains list of approved claims at FE providers
# file 3 contains notify compatible list mail shot
# this script is NOT optimised and will perform many n+1 queries

academic_year = AcademicYear.new(2025)

headers1 = ["ukprn", "name", "total", "approved", "rejected", "max_award_amount", "lower_award_amount"]
headers2 = [
  "ukprn",
  "provider_name",
  "claim_reference",
  "claimant",
  "subjects",
  "submitted_at",
  "verifier",
  "verified_at",
  "award_amount"
]

file1 = File.open("fe-providers-email.csv", "w")
file1.write(headers1.join(",") + "\n")

file2 = File.open("fe-claimants-email.csv", "w")
file2.write(headers2.join(",") + "\n")

max_claim_count_for_providers = 0

Policies::FurtherEducationPayments::EligibleFeProvider
  .by_academic_year(academic_year)
  .each do |provider|
  array = [
    provider.ukprn,
    "\"#{provider.name}\"",
    provider.claims.where(academic_year:).count,
    provider.claims.where(academic_year:).approved.count,
    provider.claims.where(academic_year:).rejected.count,
    provider.max_award_amount,
    provider.lower_award_amount
  ]

  file1.write(array.join(",") + "\n")

  max_claim_count_for_providers = [
    max_claim_count_for_providers,
    provider.claims.where(academic_year:).approved.count
  ].max

  provider.claims.where(academic_year:).approved.each do |claim|
    array = [
      claim.school.ukprn,
      "\"#{claim.school.name}\"",
      claim.reference,
      claim.full_name,
      "\"#{claim.eligibility.subjects_taught.join(",")}\"",
      claim.submitted_at,
      claim.eligibility.verified_by&.full_name,
      claim.eligibility.provider_verification_completed_at,
      claim.award_amount
    ]

    file2.write(array.join(",") + "\n")
  end
end

additional_headers = max_claim_count_for_providers.times.flat_map do |index|
  [
    "claim_reference_#{index+1}",
    "claimant_#{index+1}",
    "subjects_#{index+1}",
    "submitted_at_#{index+1}",
    "verifier_#{index+1}",
    "verified_at_#{index+1}",
    "award_amount_#{index+1}"
  ]
end

headers3 = ["ukprn", "name", "total", "approved", "rejected", "max_award_amount", "lower_award_amount"] + additional_headers

file3 = File.open("fe-notify.csv", "w")
file3.write(headers3.join(",") + "\n")

Policies::FurtherEducationPayments::EligibleFeProvider
  .by_academic_year(academic_year)
  .each do |provider|
  array = [
    provider.ukprn,
    "\"#{provider.name}\"",
    provider.claims.where(academic_year:).count,
    provider.claims.where(academic_year:).approved.count,
    provider.claims.where(academic_year:).rejected.count,
    provider.max_award_amount,
    provider.lower_award_amount
  ]

  provider.claims.where(academic_year:).approved.each do |claim|
    array += [
      claim.reference,
      claim.full_name,
      "\"#{claim.eligibility.subjects_taught.join(",")}\"",
      claim.submitted_at,
      claim.eligibility.verified_by&.full_name,
      claim.eligibility.provider_verification_completed_at,
      claim.award_amount
    ]
  end

  file3.write(array.join(",") + "\n")
end

nil
