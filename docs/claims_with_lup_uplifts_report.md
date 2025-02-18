# Generate a CSV report of claims that are eligible for a Targeted Retention Incentive top up

After Targeted Retention Incentive award amounts are uplift we need identify existing claims which are
affected.

This is a quick way to create a CSV output of all the claims referring to claims
of the affected schools.

The last two columns will show claims if a claim needs their award amount
amended if not payrolled and if payrolled they are candidates for a top up
payment.

Obtain a ruby console following instructions in the README.md.

Modify the `school_urns` list of schools obtained from the Claim team. Copy and
paste the following code into the ruby console. Copy and save the CSV output
into a file and securely share with the Claim team.

```ruby
school_urns = %w(
  123456
  234567
  345678
).uniq

school_ids = School.where(urn: school_urns).pluck(:id)
elig_ids = Policies::LevellingUpPremiumPayments::Eligibility.where(current_school_id: school_ids).pluck(:id)

csv_output = CSV.generate(headers: true) do |csv|
  csv << ["claim_reference", "full_name", "trn", "school_urn", "school_name", "submitted_date", "claim_status", "award_amount", "new_award_amount"]

  current_academic_year = Policies::LevellingUpPremiumPayments.current_academic_year

  elig_ids.each do |elig_id|
    elig = Policies::LevellingUpPremiumPayments::Eligibility.find(elig_id)
    claim = elig.claim

    next unless claim.submitted?

    status = nil
    if claim.payrolled?
      status = "payrolled"
    elsif claim.latest_decision&.approved?
      status = "awaiting_payroll"
    elsif claim.latest_decision&.rejected?
      status = "rejected"
    else
      status = "awaiting_decision"
    end

    new_award_amount = Policies::LevellingUpPremiumPayments::Award.where(school: claim.eligibility.current_school, academic_year: current_academic_year.to_s).first.award_amount

    csv << [claim.reference, claim.full_name, claim.teacher_reference_number, elig.current_school.urn, elig.current_school.name, claim.submitted_at.strftime("%d/%m/%Y"), status, claim.award_amount_with_topups, new_award_amount]
  end
end

puts csv_output
```
