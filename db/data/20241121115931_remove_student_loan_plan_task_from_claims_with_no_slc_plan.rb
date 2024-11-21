# Run me with `rails runner db/data/20241121115931_remove_student_loan_plan_task_from_claims_with_no_slc_plan.rb`

# Put your Ruby code here
claim_ids = Claim
  .select(:id)
  .joins(:notes)
  .joins(:tasks)
  .where(student_loan_plan: nil)
  .where("notes.body ilike ?", "%[SLC Student loan plan] - Matched%")
  .where(tasks: {name: "student_loan_plan", passed: true})

tasks_to_destroy = Task.where(
  claim_id: claim_ids,
  name: "student_loan_plan",
  passed: true
)

if tasks_to_destroy.count == 704
  tasks_to_destroy.destroy_all
else
  puts "Expected to find 704 tasks, but found #{tasks_to_destroy.count}"
end
