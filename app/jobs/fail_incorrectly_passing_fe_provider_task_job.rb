class FailIncorrectlyPassingFeProviderTaskJob < ApplicationJob
  def perform(run = false)
    dry_run = !run

    current_fe_claims = Claim
      .by_policy(Policies::FurtherEducationPayments)
      .by_academic_year(AcademicYear.current)
      .joins(
        <<~SQL
          JOIN further_education_payments_eligibilities
          ON further_education_payments_eligibilities.id = claims.eligibility_id
        SQL
      )

    passing_provider_verification_task = Task.fe_provider_verification_v2.passed

    fe_claims_passing_provider_verification = current_fe_claims
      .joins(:tasks)
      .merge(passing_provider_verification_task)

    teaching_hours_too_high = Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "between_2_5_and_12",
      teaching_hours_per_week: %w[more_than_20 more_than_12]
    )

    teaching_hours_too_low = Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: %w[more_than_12 more_than_20],
      teaching_hours_per_week: "between_2_5_and_12"
    )

    teaching_hours_mismatch = teaching_hours_too_high.or(teaching_hours_too_low)

    insufficient_teaching_hours = Policies::FurtherEducationPayments::Eligibility.where(
      provider_verification_teaching_hours_per_week: "less_than_2_5"
    )

    should_fail_checks = teaching_hours_mismatch.or(insufficient_teaching_hours)

    claims = fe_claims_passing_provider_verification.merge(should_fail_checks)

    admin = DfeSignIn::User.find_by!(email: "Richard2.LYNCH@education.gov.uk")

    puts
    puts "#{claims.count} claims will be updated"
    puts
    puts claims.pluck(:reference)
    puts

    if !dry_run
      claims.includes(:tasks).each do |claim|
        task = claim.tasks.fe_provider_verification_v2.first

        decision = claim.latest_decision

        ApplicationRecord.transaction do
          task.update! passed: false

          if decision&.approved?
            form = Admin::UndoDecisionForm.new(
              claim: claim,
              decision: decision,
              current_admin: admin,
              params: {
                notes: "Incorrectly passing provider verification task"
              }
            )

            unless form.save
              puts "Failed to update #{claim.reference}"
              puts form.errors.full_messages.to_sentence
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end
  end
end
