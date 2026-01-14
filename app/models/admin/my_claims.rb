module Admin
  class MyClaims
    attr_reader :current_admin

    def initialize(current_admin:)
      @current_admin = current_admin
    end

    def overdue
      current_admin
        .assigned_claims
        .filter do |claim|
          claim.decision_deadline_date < Date.today
        end
    end

    def due_today
      current_admin
        .assigned_claims
        .filter do |claim|
          claim.decision_deadline_date == Date.today
        end
    end

    def due_in_7_days
      range = Date.today..7.days.from_now

      current_admin
        .assigned_claims
        .filter do |claim|
          range.include?(claim.decision_deadline_date)
        end
    end

    def on_hold
      current_admin
        .assigned_claims
        .held
    end

    def all_claims
      @all_claims ||= current_admin
        .assigned_claims
        .sort_by do |claim|
          [claim.decision_deadline_date, claim.submitted_at]
        end
    end
  end
end
