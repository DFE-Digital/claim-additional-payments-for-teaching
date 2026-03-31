class TriggerCensusSubjectsTaughtJob < ApplicationJob
  def perform
    admin_user = DfeSignIn::User.find_by!(email: "james.grant@education.gov.uk")

    Claim
      .by_policies([
        Policies::TargetedRetentionIncentivePayments,
        Policies::StudentLoans
      ])
      .by_academic_year(AcademicYear.current)
      .awaiting_task("census_subjects_taught")
      .find_each do |claim|
        AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught.new(
          claim: claim,
          admin_user: admin_user
        ).perform
      end
  end
end
