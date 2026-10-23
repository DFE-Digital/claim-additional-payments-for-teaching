# Run me with `rails runner db/data/20261023135812_qa_thresholds.rb`

Journeys::TeacherStudentLoanReimbursement.configuration.update!(
  approved_min_qa_threshold: 10,
  rejected_min_qa_threshold: 10
)

Journeys::TargetedRetentionIncentivePayments.configuration.update!(
  approved_min_qa_threshold: 10,
  rejected_min_qa_threshold: 10
)

Journeys::GetATeacherRelocationPayment.configuration.update!(
  approved_min_qa_threshold: 100,
  rejected_min_qa_threshold: 10
)

Journeys::FurtherEducationPayments.configuration.update!(
  approved_min_qa_threshold: 10,
  rejected_min_qa_threshold: 10
)

Journeys::EarlyYearsPayment::Provider::Start.configuration.update!(
  approved_min_qa_threshold: 10,
  rejected_min_qa_threshold: 10
)

Journeys::EarlyYearsTeachersFinancialIncentivePayments.configuration.update!(
  approved_min_qa_threshold: 100,
  rejected_min_qa_threshold: 100
)
