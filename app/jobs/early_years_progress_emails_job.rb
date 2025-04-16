class EarlyYearsProgressEmailsJob < ApplicationJob
  def perform
    periods_after_submission = [2.months, 5.months]
    today = Date.today

    periods_after_submission.each do |period_after_submission|
      previous_date = today - period_after_submission

      # handle when current month has more days then previous month
      if today.last_day_of_the_month? && (today.day > previous_date.end_of_month.day)
        next
      end

      window_open = previous_date.beginning_of_day

      # handle when previous month has more days that current month
      window_close = if today.last_day_of_the_month? && (previous_date.end_of_month.day > today.day)
        previous_date.end_of_month.end_of_day
      else # normal 1:1
        previous_date.end_of_day
      end

      Claim
        .by_policy(Policies::EarlyYearsPayments)
        .awaiting_decision
        .where(submitted_at: window_open..window_close)
        .find_each do |claim|
          EarlyYearsPaymentsMailer.with(claim:).progress_update.deliver_later
        end
    end
  end
end
