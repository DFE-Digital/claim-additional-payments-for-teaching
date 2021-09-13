class ClaimStats < ApplicationRecord
  require "csv"

  self.primary_key = "claim_id"

  def readonly?
    true
  end

  class << self
    def daily(date: Date.today)
      ActiveRecord::Base.connection.execute(
        <<~SQL
          SELECT
            policy,
            AVG(submission_length)
              AS average_claim_submission_length,
            AVG(decision_length)
              AS average_claim_decision_length,
            count(claim_id) filter (where result is null)
              AS applications_started_total,
            count(claim_id) filter (where claim_submitted_at is not null)
              AS applications_submitted_total,
            count(claim_id) filter (where result = 'rejected')
              AS applications_rejected_total,
            count(claim_id) filter (where result = 'accepted')
              AS applications_accepted_total,
            count(claim_id) filter (where result is null and claim_started_at::date = '#{date.to_s}')
              AS applications_started_daily,
            count(claim_id) filter (where claim_submitted_at::date = '#{date.to_s}')
              AS applications_submitted_daily,
            count(claim_id) filter (where result = 'rejected' and decision_made_at::date = '#{date.to_s}')
              AS applications_rejected_daily,
            count(claim_id) filter (where result = 'accepted' and decision_made_at::date = '#{date.to_s}')
              AS applications_accepted_total
          FROM
            #{table_name}
          GROUP BY
            policy
        SQL
      )
    end
  
  
    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << attribute_names
  
        all.each do |row|
          csv << attribute_names.map { |attr| row.send(attr) }
        end
      end
    end
  end
end
