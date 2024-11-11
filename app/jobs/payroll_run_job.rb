class PayrollRunJob < ApplicationJob
  def perform(payroll_run, claim_ids, topup_ids)
    claims = Claim.where(id: claim_ids)
    topups = Topup.where(id: topup_ids)

    ActiveRecord::Base.transaction do
      [claims, topups].reduce([], :concat).group_by(&:national_insurance_number).each_value do |grouped_items|
        # associates the claim to the payment, for Topup that's its associated claim
        grouped_claims = grouped_items.map { |i| i.is_a?(Topup) ? i.claim : i }

        # associates the payment to the Topup, so we know it's payrolled
        group_topups = grouped_items.select { |i| i.is_a?(Topup) }

        award_amount = grouped_items.map(&:award_amount).compact.sum(0)
        Payment.create!(payroll_run: payroll_run, claims: grouped_claims, topups: group_topups, award_amount: award_amount)
      end

      payroll_run.complete!
    end
  rescue => e
    payroll_run.failed!
    raise e
  end
end
