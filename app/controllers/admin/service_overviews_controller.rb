module Admin
  class ServiceOverviewsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      journeys_with_current_step_counts = Journeys::Session
        .unsubmitted
        .select(
          <<~SQL
            journey,
            steps->>(jsonb_array_length(steps) - 1) AS current_step,
            COUNT(*) AS sessions_count
          SQL
        )
        .where(created_at: 1.week.ago..)
        .group(:journey, :current_step)

      @journeys = Journeys::Session
        .from(journeys_with_current_step_counts, :journeys_sessions)
        .where.not(current_step: nil)
        .select(
          <<~SQL
            journey AS name,
            jsonb_object_agg(current_step, sessions_count) AS step_counts
          SQL
        ).group(:journey)

      claims_with_dates_and_counts = Claim
        .select(
          <<~SQL
            policy,
            DATE(created_at) AS submission_date,
            COUNT(*) AS claims_count
          SQL
        )
        .where(created_at: 1.week.ago..)
        .group(:policy, :submission_date)

      @submitted_claims_by_date = Claim
        .from(claims_with_dates_and_counts, :claims)
        .select(
          <<~SQL
            submission_date,
            jsonb_object_agg(
              policy,
              claims_count
            ) AS policy_counts
          SQL
        )
        .group(:submission_date)
        .order(submission_date: :desc)
    end
  end
end
