module Payroll
  class Projection
    def total_award_amount
      claim_scope.sum(:award_amount)
    end

    def number_of_claims_for_policy(policy)
      claim_scope.by_policy(policy).count
    end

    def total_claim_amount_for_policy(policy)
      claim_scope.by_policy(policy).sum(:award_amount)
    end

    def number_of_topups_for_policy(policy)
      topup_scope.joins(:claim).merge(Claim.by_policy(policy)).count
    end

    def total_topup_amount_for_policy(policy)
      topup_scope.joins(:claim).merge(Claim.by_policy(policy)).sum(:award_amount)
    end

    def claims_count
      claim_scope.count
    end

    def topups_count
      topup_scope.count
    end

    def month_name
      next_payroll_run_date.strftime("%B")
    end

    private

    def claim_scope
      scope = Claim.where(id: Claim.where.missing(:payments))
      scope = scope.not_rejected.where(decision_deadline: ..next_payroll_run_date)
      scope = scope.or(Claim.where(id: Claim.payrollable.select(:id)))
      scope.with_award_amounts
    end

    # Topups will go into the nearest payroll run
    def topup_scope
      Topup.payrollable
    end

    def previous_payroll_run_date
      PayrollRun.maximum(:created_at)
    end

    def next_payroll_run_date
      previous_payroll_run_date + 1.month
    end
  end
end
