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
          <<~SQL.squish
            SELECT
            '#{date}' AS extract_date,
              policy,
              ROUND(AVG(submission_length))
                AS average_claim_submission_length,
              ROUND(AVG(decision_length))
                AS average_claim_decision_length,
              COUNT(claim_id)
                AS applications_started_total,
              COUNT(claim_id) filter (where claim_submitted_at < '#{date.end_of_day}')
                AS applications_submitted_total,
              COUNT(claim_id) filter (where result = 'rejected' and decision_made_at < '#{date.end_of_day}')
                AS applications_rejected_total,
              COUNT(claim_id) filter (where result = 'accepted' and decision_made_at < '#{date.end_of_day}')
                AS applications_accepted_total,
              COUNT(claim_id) filter (where claim_started_at::date = '#{date}')
                AS applications_started_daily,
              COUNT(claim_id) filter (where claim_started_at::date = '#{date}' and claim_submitted_at::date = '#{date}')
                AS applications_submitted_daily,
              COUNT(claim_id) filter (where result = 'rejected' and decision_made_at::date = '#{date}')
                AS applications_rejected_daily,
              COUNT(claim_id) filter (where result = 'accepted' and decision_made_at::date = '#{date}')
                AS applications_accepted_daily
            FROM
              #{ClaimStats.table_name}
            WHERE
              claim_started_at < '#{date.end_of_day}'
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
