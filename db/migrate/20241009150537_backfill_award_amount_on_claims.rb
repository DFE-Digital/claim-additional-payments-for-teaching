class BackfillAwardAmountOnClaims < ActiveRecord::Migration[7.0]
  def change
    policies_with_award_amounts = Policies::POLICIES.reject do |p|
      p == Policies::StudentLoans
    end

    policies_with_award_amounts.each do |policy|
      eligibility_class = policy::Eligibility
      eligibility_table = eligibility_class.table_name

      execute <<-SQL
        UPDATE claims
        SET award_amount = #{eligibility_table}.award_amount
        FROM #{eligibility_table}
        WHERE claims.eligibility_id = #{eligibility_table}.id
        AND claims.eligibility_type = '#{eligibility_class.name}'
        AND claims.award_amount IS NULL
      SQL
    end

    execute <<-SQL
      UPDATE claims
      SET award_amount = student_loans_eligibilities.student_loan_repayment_amount
      FROM student_loans_eligibilities
      WHERE claims.eligibility_id = student_loans_eligibilities.id
      AND claims.eligibility_type = 'Policies::StudentLoans::Eligibility'
      AND claims.award_amount IS NULL
    SQL
  end
end
