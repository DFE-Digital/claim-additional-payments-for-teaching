require "csv"

class ClaimStats
  class Daily
    class << self
      def to_csv(date: Date.yesterday)
        results = daily(date: date)
        CSV.generate(headers: true) do |csv|
          csv << results.columns
    
          results.rows.each do |row|
            csv << row
          end
        end
      end

      def daily(date: Date.yesterday)
        ActiveRecord::Base.connection.exec_query(
          <<~SQL
            SELECT
            '#{date.to_s}' AS extract_date,
              policy,
              ROUND(AVG(submission_length))
                AS average_claim_submission_length,
              ROUND(AVG(decision_length))
                AS average_claim_decision_length,
              count(claim_id)
                AS applications_started_total,
              count(claim_id) filter (where claim_submitted_at is not null)
                AS applications_submitted_total,
              count(claim_id) filter (where result = 'rejected')
                AS applications_rejected_total,
              count(claim_id) filter (where result = 'accepted')
                AS applications_accepted_total,
              count(claim_id) filter (where claim_started_at::date = '#{date.to_s}')
                AS applications_started_daily,
              count(claim_id) filter (where claim_submitted_at::date = '#{date.to_s}')
                AS applications_submitted_daily,
              count(claim_id) filter (where result = 'rejected' and decision_made_at::date = '#{date.to_s}')
                AS applications_rejected_daily,
              count(claim_id) filter (where result = 'accepted' and decision_made_at::date = '#{date.to_s}')
                AS applications_accepted_daily
            FROM
              #{ClaimStats.table_name}
            GROUP BY
              policy
            ORDER BY
              policy
          SQL
        )
      end
    end
  end
end