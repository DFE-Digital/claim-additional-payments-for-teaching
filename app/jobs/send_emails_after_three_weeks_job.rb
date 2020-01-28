# Runs every morning at 8am. Finds claims which are not yet checked and which
# are three weeks old, and sends an email saying we are still in the process of
# checking.

class SendEmailsAfterThreeWeeksJob < CronJob
  self.cron_expression = "0 8 * * *"

  def perform
    Rails.logger.info "Sending three-week emails to #{three_week_old_unchecked_claims.count} unchecked claims from the database"
    three_week_old_unchecked_claims.each do |claim|
      ClaimMailer.update_after_three_weeks(claim).deliver_later
    end
  end

  private

  def three_week_old_unchecked_claims
    Claim.awaiting_checking.where(submitted_at: (21.days.ago.beginning_of_day...21.days.ago.end_of_day))
  end
end
