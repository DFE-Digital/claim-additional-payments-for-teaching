# Run me with `rails runner db/data/20211122150703_update_award_amount_for_existing_ecp_eligibilities.rb`

# Put your Ruby code here

# Back-fills EarlyCareerPayments::Eligibilities award_amount as previously was always a dynamic
# look-up based on subject, itt-year, and claim academic year along with the lookup against
# the school to determine if an uplift should be applied
# Until now this scenario has meant that award_amount is not peristed and wherever award_amount was used
# in the Admin journey (displaying claim summary, and at time of generating a payment during the
# generation of a new payroll run

# This task is a one off-task and is split into two parts.
# 1) - take all payments made, use their award_amount to populate the claim.eligibility.award_amount
# 2) - take all remaining claims and at the time of running call the dynamic claim.eligibility.award_amount
#      method to populate the award_amount.

# This will mean going forwards that with the new code every EarlyCareerPayments::Eligibility will have the
# award_amount set at the time the claimant chooses to 'Continue' on the journey on the 'Eligibility Confirmed' screen

private

class BackfillError < StandardError; end

def claims_with_payment(claims)
  processed = 0
  skipped = 0
  errors = 0

  claims.each do |claim|
    puts "claim reference: #{claim.reference}"
    payment = claim.payment
    if payment.award_amount.nil?
      puts "Error! Claim back-fill failed: Payment award_amount.nil? #{payment.award_amount.nil?}"
      errors += 1
    elsif payment.award_amount.present?
      if claim.eligibility.read_attribute(:award_amount).nil?
        puts "Back-filling using payment #{payment.id} award_amount: #{payment.award_amount}"
        claim.eligibility.update_column(:award_amount, payment.award_amount)
        processed += 1
      else
        puts "Claim already has saved award_amount: #{claim.eligibility.award_amount}; skipping"
        skipped += 1
      end
    end
  end

  puts "------------------------------------"
  puts " - processed: #{processed}"
  puts " - skipped: #{skipped}"
  puts " - errors: #{errors}"
  puts "------------------------------------\nCompleted\n\n"
end

def other_claims(claims)
  processed = 0
  skipped = 0
  errors = 0

  claims.each do |claim|
    puts "claim reference: #{claim.reference}"
    if claim.eligibility.read_attribute(:award_amount).nil?
      puts "Back-filling using dynamic look-up for EarlyCareerPayments::Eligibility.award_amount"
      claim.eligibility.update_column(:award_amount, claim.eligibility.award_amount)
      processed += 1
    elsif claim.eligibility.read_attribute(:award_amount) < 1
      errors += 1
    else
      puts "Claim already has saved award_amount: #{claim.eligibility.award_amount}; skipping"
      skipped += 1
    end
  end

  puts "------------------------------------"
  puts " - processed: #{processed}"
  puts " - skipped: #{skipped}"
  puts " - errors: #{errors}"
  puts "------------------------------------\nCompleted\n\n"
end

public

def backfill_claims(claims, status)
  puts "====================================================="
  puts "Processing #{claims.size} #{"claim".pluralize(claims.size)} with a status of '#{status}'"
  puts "====================================================="

  if status == "payed"
    claims_with_payment(claims)
  else
    other_claims(claims)
  end
end

approved_claims = Claim.by_policy(EarlyCareerPayments).approved
payed_claims = approved_claims.where.not(payment: nil)
payable_claims = approved_claims.where(payment: nil)
rejected_claims = Claim.by_policy(EarlyCareerPayments).rejected
claims_awaiting_decisions = Claim.by_policy(EarlyCareerPayments).awaiting_decision

raise BackfillError if payed_claims.size + payable_claims.size != approved_claims.size

puts "Processing Early Career Payments that have been approved up until date #{Date.current}"
puts "#{approved_claims.count} claims that have been approved"
puts "#{payed_claims.count} claims that have been payed"
puts "#{payable_claims.count} claims that are awaiting payment"

puts "\nProcessing Early Career Payments awaiting decision up until date #{Date.current}"
puts "#{claims_awaiting_decisions.count} claims that are awaiting a decision"

puts "\nProcessing Early Career Payments that have been rejected up until date #{Date.current}"
puts "#{rejected_claims.count} claims that have been rejected"

puts "\nBack-filling claim.award_amount for these claims..."

backfill_claims(payed_claims, "payed")
backfill_claims(payable_claims, "awaiting payment")
backfill_claims(claims_awaiting_decisions, "awaiting decision")
backfill_claims(rejected_claims, "rejected")

puts "\n\nCompleted Back-filling"
claims_requiring_attention = Claim.by_policy(EarlyCareerPayments).select { |claim| claim.eligibility.reload.read_attribute(:award_amount).nil? }
puts "ECP claims requiring attention (should be 0): #{claims_requiring_attention.size}"
if claims_requiring_attention.size > 0
  puts " - claim ID's"
  pp claims_requiring_attention.map(&:reference)
else
  puts "Nothing to see here!"
end
puts "END"
