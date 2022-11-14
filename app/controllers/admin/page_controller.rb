module Admin
  class PageController < BaseAdminController
    before_action :ensure_service_team

    def index
      flash[:notice] = "There is currently no School Workforce Census data present" if SchoolWorkforceCensus.all.size.zero?

      @claims_received = Claim.current_academic_year.submitted.count
      @claims_approved = Claim.current_academic_year.approved.count
      @claims_rejected = Claim.current_academic_year.rejected.count

      @total_claims_received = Claim.submitted.count
      @claims_approaching_deadline = Claim.approaching_decision_deadline.count
      @claims_passed_decision_deadline = Claim.passed_decision_deadline.count

      @no_data_census_subjects_taught_count = ClaimStats::SchoolWorkforceCensus.no_data_census_subjects_taught_count
      @any_match_count = ClaimStats::SchoolWorkforceCensus.any_match_count
    end
  end
end
