desc "Fix TSLR claims with incorrect student loan amounts"
task fix_tslr_student_loan_amounts: :environment do |task, args|
  # SLC data duplicates:
  results = ActiveRecord::Base.connection.execute("select nino, date_of_birth, plan_type_of_deduction, amount, count(id), STRING_AGG(claim_reference, ', ') from student_loans_data group by nino, date_of_birth, plan_type_of_deduction, amount having count(id) > 1")
  ninos = results.map { |result| result["nino"] }

  # claims affected
  claims = Claim.left_joins(:payments).by_policy(Policies::StudentLoans).by_academic_year("2024/2025").where(national_insurance_number: ninos).where.not(payments: nil)

  puts "#{claims.count} claims to update"
  claims.each do |claim|
    old_amount = claim.eligibility.student_loan_repayment_amount
    new_amount = StudentLoansData.where(nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth).total_repayment_amount

    if new_amount != old_amount
      if ARGV[1] == "run"
        claim.eligibility.update!(student_loan_repayment_amount: new_amount)
        puts "updated #{claim.reference} from #{old_amount} to #{new_amount}"
      else
        puts "should update #{claim.reference} from #{old_amount} to #{new_amount}"
      end
    end
  end
end
