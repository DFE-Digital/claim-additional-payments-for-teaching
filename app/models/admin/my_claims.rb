module Admin
  class MyClaims
    attr_reader :current_admin

    def initialize(current_admin:)
      @current_admin = current_admin
    end

    def overdue
      active_scope
        .filter do |claim|
          claim.decision_deadline < Date.today
        end
    end

    def due_today
      active_scope
        .filter do |claim|
          claim.decision_deadline == Date.today
        end
    end

    def due_in_7_days
      range = Date.today..7.days.from_now

      active_scope
        .filter do |claim|
          range.include?(claim.decision_deadline)
        end
    end

    def on_hold
      current_admin
        .assigned_claims
        .held
    end

    def active_claims
      @active_claims ||= active_scope.sort_by do |claim|
        [claim.decision_deadline || future_date, claim.submitted_at || future_date]
      end
    end

    private

    def future_date
      @future_date ||= 10.years.from_now
    end

    def active_scope
      exclusion_scope = current_admin.assigned_claims.approved.or(current_admin.assigned_claims.rejected)
      exclusion_ids = exclusion_scope.select(:id)

      current_admin
        .assigned_claims
        .where.not(id: exclusion_ids)
    end
  end
end
