module Admin
  class Dashboard
    attr_reader :academic_year

    def initialize(academic_year: AcademicYear.current)
      @academic_year = academic_year
    end

    def claims_received_for_year
      @claims_received_for_year ||= Claim
        .where(academic_year: academic_year)
        .count
    end

    def claims_approved_for_year
      @claims_approved_for_year ||= Claim
        .where(academic_year: academic_year)
        .approved
        .count
    end

    def claims_rejected_for_year
      @claims_rejected_for_year ||= Claim
        .where(academic_year: academic_year)
        .rejected
        .count
    end

    def all_claims_received
      @all_claims_received ||= Claim.count
    end

    def claims_approaching_deadline
      @claims_approaching_deadline ||= Claim.approaching_decision_deadline.count
    end

    def claims_passed_decision_deadline
      @claims_passed_decision_deadline ||= Claim.passed_decision_deadline.count
    end

    def no_data_census_subjects_taught_count
      @no_data_census_subjects_taught_count ||= SchoolWorkforceCensus.no_data_census_subjects_taught_count
    end

    def any_match_count
      @any_match_count ||= SchoolWorkforceCensus.any_match_count
    end

    def fe_provider_verfication_tasks_automatically_passed
      @fe_provider_verfication_tasks_automatically_passed ||=
        Task
          .joins(:claim)
          .where(
            claim: {
              eligibility_type: "Policies::FurtherEducationPayments::Eligibility",
              academic_year: academic_year
            }
          )
          .passed_automatically
          .where(name: "provider_verification")
          .count
    end
  end
end
