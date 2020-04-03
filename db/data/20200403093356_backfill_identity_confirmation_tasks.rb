# Run this with:
#
#   rails runner db/data/20200403093356_backfill_identity_confirmation_tasks.rb
#
# Back-fills identity_confirmation tasks for all those claims that have a successfully qualification check. To now,
# identity confirmation was implied in the qualification check, but we are now recording the identity confirmation
# explicitly as its own task.
claims_with_a_passed_qualification_task = Claim.joins(:tasks).merge(Task.where(name: "qualifications", passed: true))

puts "#{claims_with_a_passed_qualification_task.count} claims that have a PASSED qualification check task"
puts "Back-filling identity confirmation tasks for these claims..."

claims_with_a_passed_qualification_task.each do |claim|
  if claim.tasks.detect { |task| task.name == "identity_confirmation" }
    puts "Claim #{claim.id}: identity_confirmation task already complete; skipping"
  elsif !claim.identity_verified?
    puts "Claim #{claim.id}: skipped GOV.UK Verify; not back-filling"
  else
    qualification_task = claim.tasks.detect { |task| task.name == "qualifications" }

    identity_confirmation_task = claim.tasks.build(
      name: "identity_confirmation",
      passed: true,
      manual: qualification_task.manual,
      created_by: qualification_task.created_by,
      created_at: qualification_task.created_at,
      updated_at: qualification_task.updated_at
    )

    if identity_confirmation_task.save
      puts "Claim #{claim.id}: identity_confirmation task back-filled"
    else
      puts "Error! Claim #{claim.id} back-fill failed: #{identity_confirmation_task.errors.full_messages.to_sentence}"
    end
  end
end
