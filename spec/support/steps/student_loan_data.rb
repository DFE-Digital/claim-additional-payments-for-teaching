def when_student_loan_data_exists
  create(:student_loans_data, nino: "PX321499A", date_of_birth: Date.new(1988, 2, 28), policy_name: Policies::FurtherEducationPayments)
end
